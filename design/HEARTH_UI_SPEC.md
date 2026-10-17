# Celador Idle — "Hearth" UI redesign (implementation handoff)

This file is written for Claude Code. It replaces the current cool purple-grey dark UI with a warm,
art-led dark theme whose palette is set per zone. It covers five screens:

| Mockup file | Screen |
|---|---|
| `mockups/Hearth.dc.html` | Zone screen, top (Southglen Meadow) |
| `mockups/HearthScrolled.dc.html` | Zone screen, scrolled (Southglen Meadow) |
| `mockups/ForestZone.dc.html` | Zone screen, top (Southwood Forest, forest palette) |
| `mockups/HearthCombat.dc.html` | Combat screen (Chicken, Southglen Meadow) |
| `mockups/HearthCraft.dc.html` | Crafting station screen (Firepit, Southglen Meadow) |

**About the mockups:**
- They are HTML design comps, not code to port. Read them for exact values (each one uses plain inline styles) and rebuild the screens as Flutter widgets.
- Their `/_blob/...` image URLs won't load outside the design tool. Use the game's existing zone art and sprite assets.
- If PNG exports are in `mockups/`, treat them as the visual source of truth.
- All sizes below are logical pixels on a 390pt-wide phone.

---

## 0. How to build this (for Claude Code)

1. **Explore first.**
   - Find the current theme and colour definitions, the zone screen, the bottom action dock, the entity/place list rows, the combat screen and the crafting/station screen.
   - Find the zone data model.
   - Report back what you found and propose a plan before editing.
2. **Build in stages.** Stop after each stage so the user can check it in the simulator:
   1. Theme tokens: a `ThemeExtension`, the fonts, and the zone palette in the zone model.
   2. Shared components: status row, tab bar, list row, sprite frame, skill ring, bottom dock, nav.
   3. Zone screen, including the collapsing art header.
   4. Combat screen.
   5. Crafting screen.
3. **Keep it visual.** Don't change game logic, timers or data flow; this is a visual refactor.
4. **No hard-coded colours.** Every colour in the screens goes through the theme extension.

---

## 1. Theme architecture

Two layers:

1. **Zone palette** (`ZonePalette`). It sets the background colours and the accent. Each zone has its own; the screens inside a zone (combat, crafting stations) use that zone's palette.
2. **Fixed semantic colours** (`GameColors`). These are the same everywhere: stat colours, XP, HP and stop.

Add a `palette` (or `paletteId`) field to the zone model. Screens get the active zone's palette from the zone they belong to. Combat and crafting screens use the palette of the zone they're in.

### 1a. Zone palettes

| Token | Southglen Meadow | Southwood Forest | Use |
|---|---|---|---|
| `bg` | `#15130F` | `#0F130E` | Screen background, dock background |
| `surface` | `#211C16` | `#182016` | Cards, list rows, ring fill, Stop / Eat buttons |
| `surfaceSunken` | `#1D1914` | `#141B12` | Tab bar and segmented-control container |
| `raised` | `#342C22` | `#26311F` | Selected tab/segment, active nav pill |
| `track` | `#2D261D` | `#222B1C` | Empty progress-bar track |
| `border` | `#2F281F` | `#232D1F` | 1px card borders |
| `borderStrong` | `#3A3226` | `#33412C` | Chip / Stop / Eat borders, ring track, dashed empty state |
| `borderOverArt` | `#4A3F30` | `#3A4A32` | Borders on chips and buttons that sit over art |
| `divider` | `#2A241C` | `#1F281B` | Dock top border, nav top border, collapsed header bottom |
| `text` | `#F2EADB` | `#ECEFDD` | Primary text |
| `textMuted` | `#B0A38C` | `#A8B39A` | Secondary text, inactive tabs, timers |
| `textSubtitle` | `#C9BDA6` | (derive) | Subtitle under the title over the art strip |
| `textNavInactive` | `#A0937C` | `#98A38A` | Inactive bottom-nav items |
| `chevron` | `#8F836E` | `#7F8A72` | Row chevrons, recipe arrow |
| `accent` | `#9BCB4F` | `#D6DE5C` | **Primary action button ONLY** |
| `onAccent` | `#16200A` | `#1A1E06` | Icon and text on the primary button |
| `accentLip` | `#6A9133` | `#959C33` | 4px bottom "lip" shadow under the primary button |

Where the accents come from:
- **Meadow:** `accent` is the grass green in the meadow art.
- **Forest:** `accent` is the sunlight on the path in the forest art.

For each new zone, take the accent from its art. `onAccent` must have at least 4.5:1 contrast with `accent`. `accentLip` is `accent` about 30% darker.

### 1b. Fixed semantic colours (all zones)

| Token | Hex | Rule |
|---|---|---|
| `exploration` | `#E0A93E` | Exploring label/bar, exploration ring, compass icons |
| `stamina` | `#4A8FE7` | Stamina bar, ring, heart icon |
| `speed` | `#E9C23A` | Speed ring, bolt icons (including the "Fast" combat style) |
| `recovery` | `#3DBE7A` | Recovery ring |
| `firemaking` | `#EE8A3A` | Firemaking ring, "Tending" label/bar, flame icons |
| `cooking` | `#B9473A` | Cooking ring (darker than firemaking so the two differ in lightness) |
| `xp` | `#E8C766` | Every XP number. XP is never pink. |
| `hp` | `#C4473A` | HP bars (enemy and player), with white text on top |
| `attack` | `#E8806B` | Attack/swords icons, combat chip icon |
| `stop` | `#E8806B` | The square on the Stop button |
| `gathering` | `#7FC08A` | Woodcutting/gathering chip icons |
| `secondaryBar` | `#CDBF9F` | Second status bar (see the open questions) |
| `timerFill` | `#8F836E` | Thin attack-timer fill in combat |

**Rule:** each colour means one thing. `accent` appears only on the primary action button. Stat colours appear only next to their stat.

### 1c. Sprite-frame tints

Each sprite sits in a rounded (radius 12) frame with a 1px border:

| Kind | Fill | Border |
|---|---|---|
| Combat creature | `#2A1F18` | `#46332A` |
| Gathering spot (pond, river) | `#1A241D` (forest: `#15231B`) | `#2E4233` (forest: `#2A4033`) |
| Crafting station (anvil) / crafting input | `#262019` | `#43382A` |
| Fire / firemaking | `#2A1E16` | `#4A3324` |
| Dungeon | `#1B1D1F` | 2px outline in the dungeon's rarity colour (keep the existing rarity mapping) |

The large "stage" panels on the combat and crafting screens use the same tints at radius 20.

### 1d. Typography

- **Screen and zone titles:** Pixelify Sans 600.
  - 30px on the expanded zone header, 24px on the collapsed header and on combat/crafting.
  - Text shadow `0 2px 0 #0B0A08` (forest: `#070906`).
- **Everything else:** Figtree, weights 500–800. Use tabular figures (`FontFeature.tabularFigures()`) on every number.
- **Loading:** use `google_fonts`, or bundle the fonts as assets.

| Element | Size / weight / colour |
|---|---|
| Row title | 17 / 700 / `text` |
| Row meta line | 13 / 600 / `textMuted` |
| XP value | 17 / 800 / `xp`, with the " xp" suffix at 13 / 600 |
| Tabs | 15 / 700 active, 15 / 600 inactive (14 on 4-tab bars) |
| Chips | 15 / 600 (active 700) |
| Section label ("PLACES") | 12 / 700, uppercase, letter-spacing 0.12em, `textMuted` |
| Ring number | 13 / 800 |
| Timers ("2.00s") | 12–13 / 700 / `textMuted` |
| Nav labels | 12 / 600 (active 700) |

---

## 2. Shared components

Build these once and reuse them on all three screen types.

### StatusRow (pinned at the top, under the safe area)
- **Size:** 48 tall, 16pt side padding.
- **Left: activity button** (44×44, radius 12, `surface` at 85% opacity, 1px `borderOverArt` border).
  - It shows the current activity: a compass icon in `exploration` while exploring, or the current target's sprite with a small count pill (e.g. "181k") overlapping the bottom edge.
- **Middle: bars,** stacked 5–6pt apart.
  - Stamina: 8px tall, `stamina` fill on a translucent `borderStrong` track.
  - Secondary bar: 4px tall, `secondaryBar` fill.
  - Optional third bar: 4px, with a timer label on the right (the forest screen shows "1.67s").
- **Right: stats,** 14 / 700, stacked 2pt apart: heart icon (`stamina`) + "990 / 990", bolt icon (`speed`) + "1.50x".

### ArtHeader (zone screens: collapsing; combat and crafting: always collapsed)
- **Expanded (360 tall, including the safe area):**
  - Zone art fills the full width from the very top of the screen, behind the status row: `BoxFit.cover`, alignment about (0, 0.1), `FilterQuality.none`.
  - Top scrim: 150 tall, a gradient from `bg` at 92% to 70% at 55% to transparent.
  - Bottom scrim: 150 tall, a gradient from transparent to `bg` at 75% at 55% to solid `bg`.
  - Title row: 48 tall, with its bottom 24pt above the bottom of the art. It contains:
    - Back button: 44×44, `bg` at 55% opacity, radius 12.
    - Pixelify title.
    - Right chip: 32 tall pill, `bg` at 70% opacity, 1px `borderOverArt` (e.g. a compass icon and the explored count).
- **Collapsed (166 tall: safe area 54 + status 48 + title row 48 + padding):**
  - The same art, cropped to a strip aligned about (0, 0.45), under a scrim running from `bg` at 94% (top) to 88% (60%) to 45% (bottom).
  - 1px `divider` along the bottom edge.
  - Title 24px.
- **Implementation:** use a `SliverAppBar` or a custom `SliverPersistentHeader`. Interpolate the title size from 30 to 24 and the art alignment as it collapses.
- **Combat and crafting screens:** always use the collapsed form, with the screen's own title and a 12 / 600 `textSubtitle` subtitle naming the zone ("Southglen Meadow"). The back button's accessibility label is "Back to <zone>".

### SegmentedTabs
- **Size:** 48 tall, 16pt side margins.
- **Container:** `surfaceSunken`, 1px `border`, radius 14, 4pt padding, 4pt gap.
- **Selected segment:** `raised`, radius 10, `text` colour.
- **Unselected segments:** transparent, `textMuted`.
- **Also used for:** the combat-style switch (Offensive / Defensive / Fast), at 44 tall with an icon before each label.

### ListRow (places and entities)
- **Size:** places 64 tall, entities 68 tall, 8pt apart.
- **Box:** `surface`, 1px `border`, radius 16, padding 8 left and 14 right, 12pt gap between items.
- **Contents:**
  - Sprite frame: 48 (places) or 52 (entities), tinted by kind (see 1c). The sprite is fitted to about 40px.
  - Title, with a meta line underneath.
  - Right side: a chevron (places), or an XP column (entities): `xp` value on top, "+N / kill" in `textMuted` underneath.
- **No coloured stripe down the left edge.** The current build has a purple one; remove it.
- **Entity meta line:** "Lv 3 · 1.57k". This replaces the count badge on the sprite and the swords chip. See the open questions about the noun after the count.
- **Place meta line:** an icon and text, e.g. "Fishing · Lv 1", "Blacksmithing", "Firemaking", "Dungeon".

### FilterChips (horizontal scroll, 16pt side padding)
- **Size:** 44 tall, radius 12, 8pt gap.
- **Active chip:** `text` fill with `bg` text.
- **Inactive chips:** `surface` fill, 1px `borderStrong` border. The count is shown in `textMuted` after the label.
- **Chip icons:** `attack` for combat, `gathering` for woodcutting.
- **Counts:** show one count. The current build shows "Entities · 9111" on the tab and "All 9106" on the chip; drop the count from the tab.

### SkillRing
- **Size:** 40×40 circle, `surface` fill. The ring is 3px wide at radius 17.
- **Fill:** full rings for maxed stats. Partial rings (level progress) draw on a `borderStrong` track with a round line cap, starting at 12 o'clock.
- **Centre:** the level number only, 13 / 800. No icon inside the ring; the current build draws the number on top of the icon.
- **Accessibility:** label like "Stamina, level 99".

### ProgressRow (activity bar)
- **Layout:** the label (13 / 700, in the activity's colour: "Exploring" `exploration`, "Tending" `firemaking`), a 6px bar in the same colour on `track`, and the timer in `textMuted`.

### ActionDock (fixed to the bottom; `bg` with a 1px `divider` top border; 12pt top padding, 16pt sides, 10–12pt between rows)
- **Fade:** a 28pt gradient from transparent to `bg` sits directly above the dock, so scrolling content fades out.
- **Optional row (44 tall):**
  - Zone screen: the ProgressRow on the left, filling the space, and four SkillRings on the right, 6pt apart.
  - Combat: the combat-style SegmentedTabs.
- **Button row (52 tall, 10pt gap):**
  - **Stop:** 52×52, `surface` fill, 1px `borderStrong`, radius 14, with a 16px rounded-3 square in `stop`. It's deliberately quiet; the current build's big red button reads as a warning.
  - **Primary:** fills the space, `accent` fill, radius 14, `onAccent` content, with a 4px `accentLip` shadow under it (`BoxShadow(offset: Offset(0,4), blurRadius: 0)`).
    - Zone screen: a play icon.
    - Combat: a play icon.
    - Crafting: the action name as text ("Light Fire", 17 / 800), with a fast-forward icon before it and a lock icon after it if relevant.
  - **Secondary (combat only):** "Eat", 92 wide, `surface` fill, 1px `borderStrong`, a food icon in `exploration`, then "Eat" (14 / 700) over the food count (12 / 600, `textMuted`).
- **BottomNav (68 tall, 1px `divider` top border, 5 equal items):**
  - Active item: a 52×28 `raised` pill behind the icon, with the label in `text`.
  - Inactive items: `textNavInactive`.

Dock heights: zone screen 200, combat 198, crafting 144 (it has no optional row).

### EmptyState
- **Box:** 1px dashed `borderStrong`, radius 16, transparent fill, 76–100 tall.
- **Content:** an icon and a 14 / 600 `textMuted` message, centred (e.g. "No loot this session", "Nothing cooked this session").

---

## 3. Screens

### 3a. Zone screen (`Hearth`, `HearthScrolled`, `ForestZone`)
From top to bottom: StatusRow over the art, then ArtHeader (expanded, collapsing on scroll), then the scrolling content:
1. **SegmentedTabs:** "Entities", "Loot · N", "Info". 12pt below the header.
2. **Section label "PLACES"** (forest mockup), then the place rows.
3. **FilterChips.**
4. **Entity rows.**

Then the ActionDock: ProgressRow ("Exploring") with the four core rings, Stop and the primary button, and the nav. In the expanded state the whole page scrolls, and the header pins at its collapsed size.

Southwood Forest uses exactly the same layout with the forest palette. Its Wolf Den row keeps the dungeon's rarity outline.

### 3b. Combat screen (`HearthCombat`) — uses its zone's palette
1. StatusRow.
2. Collapsed ArtHeader: title "Chicken", subtitle "Southglen Meadow", and a "Lv 3" chip on the right.
3. **Stage panel** (top 178, 164 tall, combat tint, radius 20):
   - The creature sprite is about 124 tall, centred, with `FilterQuality.none`, standing on a soft dark ellipse shadow (150×22, black at 45% opacity).
   - Count pill in the bottom-right corner: 28 tall, `bg` at 80% opacity, 1px `#46332A` border, showing the number only ("181k").
4. **Combatant rows** (2 rows, 52 tall each, 10pt gap). Each row has:
   - A label, 56 wide (14 / 700, `textMuted`): "Enemy" / "Player".
   - An HP bar: 22 tall, radius 7, `hp` fill on `track`, with "9 / 9" centred (13 / 800, white).
   - Under it, a 4px attack-timer bar (`timerFill`) with "2.00s".
   - On the right, 88 wide: a shield icon (`textMuted`) with defence, and a swords icon (`attack`) with attack, both 15 / 700.
5. **SegmentedTabs:** "Loot · 0", "Skills", "Buffs · 0", "Info".
6. **EmptyState:** "No loot this session".
7. **ActionDock:**
   - Combat-style switch: Offensive (swords icon in `attack`), Defensive (shield icon), Fast (bolt icon in `speed`). The selected style uses `raised`.
   - Stop, the primary button (play), and Eat.
   - Nav.

### 3c. Crafting station screen (`HearthCraft`) — uses its zone's palette
1. StatusRow. The activity button shows the current target's sprite and count.
2. Collapsed ArtHeader: title "Firepit", subtitle "Southglen Meadow", and a right chip with a flame icon (`firemaking`) and "Firemaking".
3. **Stage panel:** 148 tall, fire tint, with the station sprite about 116 tall, centred.
4. **Recipe card** (76 tall, ListRow box style). It reads **left to right, input → output**; the current build's arrow points backwards.
   - Input frame: 52px, crafting tint, with a count pill ("15").
   - A right-arrow icon (`chevron`).
   - Output frame: 52px, fire tint, with a count pill ("3.24k").
   - On the right: "Requires" (12 / 600, `textMuted`) above "Lv 15" (17 / 800).
   - Count pills: 16 tall, `bg` fill, 1px border matching the frame, 12 / 700, overlapping the frame's bottom-right corner by about 6pt.
5. **ProgressRow:** "Tending" in `firemaking`.
6. **Skill rings:** five 40px rings, centred, 14pt apart: Firemaking (`firemaking`, partial), Cooking (`cooking`, partial), Stamina, Speed, Recovery.
7. **SegmentedTabs:** "Cooked · 0", "Buffs · 0", "Info".
8. **EmptyState:** "Nothing cooked this session" (flame icon).
9. **ActionDock:** Stop and the primary button showing [fast-forward] "Light Fire" [lock], then the nav. There's no separate label above the buttons; the action name is on the button itself.

---

## 4. Rules (check every screen)
- `accent` is used only on the primary action button.
- Stat colours appear only next to their stat. XP is always `xp`. HP is always `hp`.
- Everything tappable is at least 44pt in both directions. Rings are 40, so pad their tap area to 44.
- Text contrast is at least 4.5:1 against `surface` and `bg`. The tokens above pass; check any new ones.
- Sprites and art render with `FilterQuality.none`.
- Add accessibility labels to every icon-only button (Back, Stop, Start/Fight, rings, the activity button).

## 5. Open questions (ask the user; don't guess)
1. **Second status bar:** what does it track? Label it, or remove it if it's redundant. Its colour is currently `secondaryBar`.
2. **Count nouns:** what do the counts on creatures mean (e.g. "1.57k" in list rows, "181k" on the combat stage)? The user removed the word "kills" from the combat mockup, so show the number only until this is confirmed.
3. **Crafting count pills:** confirm what "3.24k" on the output and "15" on the input mean (amount made / amount owned).
4. **Lock icon:** what does the lock on the crafting primary button mean? If the action is unavailable, render the primary button disabled (`surface` fill, `textMuted` content, no lip) instead of `accent`.
5. **Other zones:** the palette for each remaining zone. Use the same derivation: a background tinted toward the art's dominant hue, and the accent taken from the art's brightest colour.
