#!/usr/bin/env bash
#
# release_ios.sh — bump the build number, archive, export a signed IPA, and
# upload it to App Store Connect.
#
# Export compliance is declared in ios/Runner/Info.plist
# (ITSAppUsesNonExemptEncryption = false), so App Store Connect marks each
# build compliant on ingest and never prompts. The app makes no network calls
# and links no crypto libraries. Revisit that key if that ever changes.
#
# One-time setup (see --help):
#   ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8
#   export ASC_KEY_ID=... ASC_ISSUER_ID=...
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PUBSPEC="pubspec.yaml"
EXPORT_OPTIONS="ios/ExportOptions.plist"
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"
IPA_DIR="build/ios/ipa"
XCARCHIVE="build/ios/archive/Runner.xcarchive"

DRY_RUN=0
ALLOW_DIRTY=0
SKIP_TESTS=0
FORCED_BUILD=""

die()  { printf '\n\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }

usage() {
  cat <<'USAGE'
usage: tools/release_ios.sh [options]

  --dry-run           Build and sign, but stop before uploading. Leaves
                      pubspec.yaml unmodified and makes no commit.
  --allow-dirty       Proceed even with uncommitted changes.
  --skip-tests        Skip `flutter analyze` and `flutter test`.
  --build-number N    Use N instead of incrementing pubspec's build number.
  -h, --help          Show this message.

One-time setup:
  1. App Store Connect -> Users and Access -> Integrations -> App Store
     Connect API -> create a key with the App Manager role.
  2. Download AuthKey_<KEYID>.p8 (downloadable exactly once), then:
       mkdir -p ~/.appstoreconnect/private_keys
       mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/private_keys/
  3. In your shell profile:
       export ASC_KEY_ID=XXXXXXXXXX
       export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=1; shift ;;
    --allow-dirty)  ALLOW_DIRTY=1; shift ;;
    --skip-tests)   SKIP_TESTS=1; shift ;;
    --build-number) FORCED_BUILD="${2:-}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *)              usage >&2; die "unknown option: $1" ;;
  esac
done

[[ -n "$FORCED_BUILD" && ! "$FORCED_BUILD" =~ ^[0-9]+$ ]] && \
  die "--build-number must be a positive integer, got: $FORCED_BUILD"

# --- 1. preflight: credentials -----------------------------------------------
# Checked before anything slow, so a missing key fails in a second rather than
# after a ten-minute build.
if (( ! DRY_RUN )); then
  step "Preflight: App Store Connect credentials"
  [[ -n "${ASC_KEY_ID:-}"    ]] || die "ASC_KEY_ID is not set. Run with --help for setup instructions."
  [[ -n "${ASC_ISSUER_ID:-}" ]] || die "ASC_ISSUER_ID is not set. Run with --help for setup instructions."
  KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
  [[ -f "$KEY_PATH" ]] || die "No API key at $KEY_PATH. Run with --help for setup instructions."
  note "key    $KEY_PATH"
  note "issuer $ASC_ISSUER_ID"
else
  step "Preflight skipped (--dry-run): no upload will be attempted"
fi

# --- 2. clean-tree guard ------------------------------------------------------
step "Checking working tree"
if [[ -n "$(git status --porcelain)" ]]; then
  if (( ALLOW_DIRTY )); then
    note "tree is dirty; continuing because --allow-dirty was passed"
  else
    git status --short
    die "working tree is dirty. Commit your changes, or pass --allow-dirty."
  fi
else
  note "clean"
fi

# --- 3. quality gate ----------------------------------------------------------
if (( SKIP_TESTS )); then
  step "Quality gate skipped (--skip-tests)"
else
  # This project carries pre-existing lint debt (deprecated withOpacity calls,
  # SCREAMING_CASE enum constants). Gate on real errors only, or every release
  # is blocked by warnings that predate it.
  step "Running flutter analyze (errors only)"
  flutter analyze --no-fatal-infos --no-fatal-warnings
  step "Running flutter test"
  flutter test
fi

# --- 4. drift guard -----------------------------------------------------------
# pubspec.yaml is the source of truth, but it has drifted from reality before:
# the number used to live only in the generated ios/Flutter/Generated.xcconfig.
# Compare against local archives and report rather than silently rewriting, so
# a stale pubspec is never papered over. Pruned archives only weaken this
# check; they cannot cause a false failure.
step "Checking build number against local archives"

read_version_line() {
  grep -E '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' "$PUBSPEC" | head -1
}

VERSION_LINE="$(read_version_line)" || true
[[ -n "$VERSION_LINE" ]] || \
  die "could not find a 'version: X.Y.Z+N' line in $PUBSPEC"

CURRENT_NAME="${VERSION_LINE#version: }"; CURRENT_NAME="${CURRENT_NAME%%+*}"
CURRENT_BUILD="${VERSION_LINE##*+}"

# The archive directory holds every app built on this machine, so match on
# bundle ID or another project's build numbers leak into the comparison.
BUNDLE_ID="$(grep -m1 -E 'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;' ios/Runner.xcodeproj/project.pbxproj \
  | sed -E 's/.*PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);.*/\1/' | tr -d '"')"
[[ -n "$BUNDLE_ID" ]] || die "could not read PRODUCT_BUNDLE_IDENTIFIER from the Xcode project"

HIGHEST_ARCHIVED=0
if [[ -d "$ARCHIVE_DIR" ]]; then
  while IFS= read -r plist; do
    id="$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleIdentifier" "$plist" 2>/dev/null || true)"
    [[ "$id" == "$BUNDLE_ID" ]] || continue
    v="$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$plist" 2>/dev/null || true)"
    [[ "$v" =~ ^[0-9]+$ ]] && (( v > HIGHEST_ARCHIVED )) && HIGHEST_ARCHIVED="$v"
  done < <(find "$ARCHIVE_DIR" -maxdepth 3 -name Info.plist -path '*.xcarchive/*' 2>/dev/null)
fi

note "pubspec.yaml    build $CURRENT_BUILD (version $CURRENT_NAME)"
note "local archives  build $HIGHEST_ARCHIVED (highest for $BUNDLE_ID)"

if (( CURRENT_BUILD < HIGHEST_ARCHIVED )); then
  die "$PUBSPEC says build $CURRENT_BUILD but a local archive is already at build $HIGHEST_ARCHIVED.
       App Store Connect would reject a duplicate or lower build number.
       Set $PUBSPEC to at least 1.0.0+$HIGHEST_ARCHIVED, or pass --build-number to override."
fi

# --- 5. bump ------------------------------------------------------------------
if [[ -n "$FORCED_BUILD" ]]; then
  NEW_BUILD="$FORCED_BUILD"
else
  NEW_BUILD=$(( CURRENT_BUILD + 1 ))
fi
NEW_VERSION="${CURRENT_NAME}+${NEW_BUILD}"

step "Bumping build number: ${CURRENT_NAME}+${CURRENT_BUILD} -> ${NEW_VERSION}"

PUBSPEC_BACKUP="$(mktemp)"
cp "$PUBSPEC" "$PUBSPEC_BACKUP"

restore_pubspec() {
  if [[ -f "$PUBSPEC_BACKUP" ]]; then
    cp "$PUBSPEC_BACKUP" "$PUBSPEC"
    rm -f "$PUBSPEC_BACKUP"
  fi
}
# Any failure after this point leaves pubspec.yaml exactly as it was found.
trap restore_pubspec EXIT

sed -i '' "s|^version: .*$|version: ${NEW_VERSION}|" "$PUBSPEC"
grep -n '^version:' "$PUBSPEC" | sed 's/^/    /'

# --- 6. build + archive -------------------------------------------------------
# `flutter build ipa` runs `xcodebuild archive` and then `-exportArchive` with
# the options plist, producing both the .xcarchive and a signed IPA.
step "Building and archiving (flutter build ipa)"
flutter build ipa --release --export-options-plist="$EXPORT_OPTIONS"

IPA="$(find "$IPA_DIR" -maxdepth 1 -name '*.ipa' 2>/dev/null | head -1)"
[[ -n "$IPA" ]] || die "no .ipa produced under $IPA_DIR"

step "Archive complete"
note "archive $XCARCHIVE"
note "ipa     $IPA"

# Confirm the compliance declaration actually reached the binary, so a silent
# Info.plist regression surfaces here rather than as an ASC prompt.
BUILT_PLIST="$XCARCHIVE/Products/Applications/Runner.app/Info.plist"
if [[ -f "$BUILT_PLIST" ]]; then
  COMPLIANCE="$(/usr/libexec/PlistBuddy -c "Print :ITSAppUsesNonExemptEncryption" "$BUILT_PLIST" 2>/dev/null || echo "MISSING")"
  BUILT_BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$BUILT_PLIST" 2>/dev/null || echo "?")"
  note "built build number       $BUILT_BUILD"
  note "encryption compliance    ITSAppUsesNonExemptEncryption = $COMPLIANCE"
  [[ "$COMPLIANCE" == "false" ]] || \
    die "ITSAppUsesNonExemptEncryption is '$COMPLIANCE' in the built app, expected 'false'.
       App Store Connect will ask for export compliance on every upload.
       Check the key in ios/Runner/Info.plist."
fi

# --- 7. dry-run stops here ----------------------------------------------------
if (( DRY_RUN )); then
  step "Dry run complete — nothing was uploaded and nothing was committed"
  note "pubspec.yaml has been restored to build $CURRENT_BUILD"
  note ""
  note "The upload this would have run:"
  note "  xcrun altool --upload-app --type ios --file \"$IPA\" \\"
  note "    --apiKey \"\$ASC_KEY_ID\" --apiIssuer \"\$ASC_ISSUER_ID\""
  note ""
  note "Re-run without --dry-run to ship build $NEW_BUILD."
  exit 0
fi

# --- 8. upload ----------------------------------------------------------------
step "Uploading to App Store Connect"
if xcrun altool --upload-app --type ios --file "$IPA" \
      --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"; then
  note "upload accepted"
else
  # altool's --upload-app is on its way out; xcodebuild is the modern path.
  note "altool upload failed; retrying via xcodebuild -exportArchive"
  UPLOAD_PLIST="$(mktemp -t ExportOptionsUpload).plist"
  cp "$EXPORT_OPTIONS" "$UPLOAD_PLIST"
  /usr/libexec/PlistBuddy -c "Set :destination upload" "$UPLOAD_PLIST"
  xcodebuild -exportArchive \
    -archivePath "$XCARCHIVE" \
    -exportOptionsPlist "$UPLOAD_PLIST" \
    -exportPath "$IPA_DIR" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  rm -f "$UPLOAD_PLIST"
fi

# --- 9. commit the bump -------------------------------------------------------
# Only after a successful upload, so a failed run leaves no misleading commit.
step "Recording build $NEW_BUILD in git"
trap - EXIT
rm -f "$PUBSPEC_BACKUP"
git add "$PUBSPEC"
git commit -m "release: iOS build ${NEW_BUILD} (${NEW_VERSION})"
git tag "ios-build-${NEW_BUILD}"

step "Done — build $NEW_BUILD uploaded and tagged ios-build-${NEW_BUILD}"
note "It takes App Store Connect a few minutes to finish processing."
note "Push the tag when you're ready:  git push && git push origin ios-build-${NEW_BUILD}"
