import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/save_slot_controller.dart';
import 'package:rpg/controllers/settings_controller.dart';
import 'package:rpg/data/save_slot_index.dart';

/*
settings screen contents:
-header with title
-saves section: every save slot (tap to switch), new save, reset the
 current save (confirms first)
-debug section, debug builds only: max skill level cap
*/

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Whether the debug section is drawn: always in debug builds, and in
  /// release builds compiled with `--dart-define=DEBUG_SETTINGS=true`, which
  /// tools/release_ios.sh passes for TestFlight.
  static const bool showDebugSettings =
      kDebugMode || bool.fromEnvironment('DEBUG_SETTINGS');

  /// The cap a freshly switched-on max skill level starts at.
  static const int defaultSkillLevelCap = 10;

  static const int _topSkillLevel = 99;

  Future<void> _confirmReset(
    BuildContext context,
    SaveSlotController saves,
    String saveName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start $saveName over?'),
        content: const Text(
          'All progress in this save is deleted: skills, items, gear and '
          'unlocked areas. Other saves are not touched. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('new-game-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (confirmed == true) saves.resetActive();
  }

  static String _lastPlayedLabel(DateTime? at) {
    if (at == null) return 'Never played';
    final ago = DateTime.now().difference(at);
    if (ago.inMinutes < 1) return 'Played just now';
    if (ago.inHours < 1) return 'Played ${ago.inMinutes}m ago';
    if (ago.inDays < 1) return 'Played ${ago.inHours}h ago';
    return 'Played ${ago.inDays}d ago';
  }

  Widget _slotTile(
    BuildContext context,
    SaveSlotController saves,
    SaveSlotInfo slot,
  ) {
    final active = slot.id == saves.activeSlotId;
    // the running save's summary is only written on save; say what it is
    // doing rather than how long ago it was last written
    final played = active ? 'Playing now' : _lastPlayedLabel(slot.lastPlayed);

    return ListTile(
      key: ValueKey('settings-save-${slot.id}'),
      leading: Icon(
        active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(slot.name),
      subtitle: Text('Total level ${slot.totalLevel} · $played'),
      selected: active,
      enabled: !saves.busy,
      onTap: active ? null : () => saves.switchTo(slot.id),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final saves = context.watch<SaveSlotController>();
    final cap = controller.maxSkillLevel;
    final activeName = saves.slots
        .firstWhere(
          (s) => s.id == saves.activeSlotId,
          orElse: () => SaveSlotInfo(id: '', name: 'this save'),
        )
        .name;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Text(
                "Settings",
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            _sectionHeader(context, "Saves"),
            for (final slot in saves.slots) _slotTile(context, saves, slot),
            ListTile(
              key: const ValueKey('settings-new-save'),
              leading: const Icon(Icons.add),
              title: const Text("New save"),
              subtitle: const Text("Start a fresh game in a new slot"),
              enabled: !saves.busy,
              onTap: saves.createSlot,
            ),
            ListTile(
              key: const ValueKey('settings-reset-save'),
              leading: Icon(
                Icons.restart_alt,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                "Start $activeName over",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text("Deletes all progress in this save"),
              enabled: !saves.busy,
              onTap: () => _confirmReset(context, saves, activeName),
            ),

            if (showDebugSettings) ...[
              _sectionHeader(context, "Debug"),
              SwitchListTile(
                key: const ValueKey('settings-skill-cap-switch'),
                title: const Text("Max skill level"),
                subtitle: Text(
                  cap == null
                      ? "Off"
                      : "Every skill reads at level $cap at most",
                ),
                value: cap != null,
                onChanged: (on) => controller.setMaxSkillLevel(
                  on ? defaultSkillLevelCap : null,
                ),
              ),
              if (cap != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          key: const ValueKey('settings-skill-cap-slider'),
                          min: 1,
                          max: _topSkillLevel.toDouble(),
                          divisions: _topSkillLevel - 1,
                          value: cap.clamp(1, _topSkillLevel).toDouble(),
                          label: '$cap',
                          onChanged: (v) =>
                              controller.setMaxSkillLevel(v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('$cap', textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
