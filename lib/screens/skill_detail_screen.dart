import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/player_data_controller.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../data/skill_descriptions.dart';
import '../data/skill_unlocks.dart';
import '../game_session.dart';
import '../widgets/fill_bar.dart';

class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({super.key, required this.skillId});

  final SkillId skillId;

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final _debugXpController = TextEditingController();

  @override
  void dispose() {
    _debugXpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final catalogs = context.read<GameSession>().catalogBundle;
    final skillId = widget.skillId;

    final level = controller.getSkillLevel(skillId);
    final xp = controller.getSkillXp(skillId);
    final nextLevelXp = controller.getNextLevelXp(skillId);
    final xpToLevelUp = controller.getXpToLevelUp(skillId);
    final progress = controller.getSkillProgress(skillId);

    final isTracking = controller.isTrackingXp(skillId);
    final elapsed = controller.getTrackedElapsed(skillId);
    final xpGained = controller.getTrackedXpGained(skillId);
    final xpPerHour = controller.getXpPerHour(skillId);

    final unlocks = unlocksForSkill(skillId, catalogs);

    return Scaffold(
      appBar: AppBar(title: Text(skillLabel(skillId))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, level, xp, nextLevelXp, xpToLevelUp, progress),
          const SizedBox(height: 12),
          _buildDescriptionCard(skillId),
          const SizedBox(height: 12),
          _buildTrackerCard(
            controller,
            skillId,
            isTracking,
            elapsed,
            xpGained,
            xpPerHour,
          ),
          const SizedBox(height: 12),
          _buildUnlocksCard(level, unlocks),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _buildDebugCard(controller, skillId),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int level,
    double xp,
    double nextLevelXp,
    double xpToLevelUp,
    double progress,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $level', style: const TextStyle(fontSize: 16)),
                  Text(
                    '${(progress * 100).round()}% to ${level + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FillBar(value: progress),
              const SizedBox(height: 4),
              Text(
                '${xp.round()} xp'
                '${xpToLevelUp > 0 ? ' · ${xpToLevelUp.round()} to next level' : ' · max level'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(SkillId skillId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardLabel('About'),
            const SizedBox(height: 4),
            Text(kSkillDescriptions[skillId] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerCard(
    PlayerDataController controller,
    SkillId skillId,
    bool isTracking,
    Duration elapsed,
    double xpGained,
    double xpPerHour,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _cardLabel('Xp tracker'),
                if (isTracking)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'tracking',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _trackerStat('Elapsed', _formatDuration(elapsed)),
                _trackerStat('Xp gained', xpGained.round().toString()),
                _trackerStat('Xp / hr', xpPerHour.round().toString()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isTracking
                        ? null
                        : () => controller.startXpTracker(skillId),
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isTracking
                        ? () => controller.resetXpTracker(skillId)
                        : null,
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackerStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUnlocksCard(int level, List<SkillUnlock> unlocks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardLabel('Unlocks'),
            const SizedBox(height: 4),
            if (unlocks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nothing gated behind this skill yet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              ...unlocks.map((unlock) {
                final unlocked = level >= unlock.levelRequirement;
                return Opacity(
                  opacity: unlocked ? 1 : 0.45,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          unlocked ? Icons.check : Icons.lock,
                          size: 14,
                          color: unlocked ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lv ${unlock.levelRequirement} · ${unlock.name}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          unlock.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard(PlayerDataController controller, SkillId skillId) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEBUG · SET XP',
              style: TextStyle(fontSize: 10, color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _debugXpController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    final parsed = double.tryParse(_debugXpController.text);
                    if (parsed == null) return;
                    controller.debugSetSkillXp(skillId, parsed);
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.grey,
        letterSpacing: 0.4,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
