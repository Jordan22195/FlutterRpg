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
import '../widgets/icon_renderer.dart';

class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({super.key, required this.skillId});

  final SkillId skillId;

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final _debugLevelController = TextEditingController();

  @override
  void dispose() {
    _debugLevelController.dispose();
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
          _buildGoalCard(controller, skillId, level, xp),
          const SizedBox(height: 12),
          _buildUnlocksCard(level, unlocks),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _buildDebugCard(controller, skillId, level),
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
              // the same colour this skill's ring is drawn in
              FillBar(
                value: progress,
                foregroundColor: skillRingColor(widget.skillId),
              ),
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

  Widget _buildGoalCard(
    PlayerDataController controller,
    SkillId skillId,
    int level,
    double xp,
  ) {
    const maxGoal = 99;
    final minGoal = level + 1;
    final atMax = minGoal > maxGoal;
    // a level-up can push the floor past the goal; it never drops below it
    final goal = atMax
        ? maxGoal
        : (controller.getGoalLevel(skillId) ?? minGoal).clamp(minGoal, maxGoal);

    final xpLeft = atMax
        ? 0.0
        : (controller.getXpAtLevel(skillId, goal) - xp).clamp(
            0.0,
            double.infinity,
          );
    final actionXp = controller.getLastActionXp(skillId);
    final isCombat = _isCombatSkill(skillId);
    final actions = (actionXp == null || actionXp <= 0)
        ? null
        : (xpLeft / actionXp).ceil();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardLabel('Level goal'),
            const SizedBox(height: 8),
            if (atMax)
              const Text(
                'Max level reached.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal: level $goal',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '$minGoal – $maxGoal',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Slider(
                value: goal.toDouble(),
                min: minGoal.toDouble(),
                max: maxGoal.toDouble(),
                // one stop per level; a slider needs at least one division
                divisions: maxGoal > minGoal ? maxGoal - minGoal : null,
                label: '$goal',
                onChanged: maxGoal > minGoal
                    ? (v) => controller.setGoalLevel(skillId, v.round())
                    : null,
              ),
              Row(
                children: [
                  _trackerStat('Xp left', _formatCount(xpLeft.ceil())),
                  _trackerStat(
                    isCombat ? 'Hits left' : 'Actions left',
                    actions == null ? '—' : _formatCount(actions),
                  ),
                  _trackerStat(
                    isCombat ? 'Avg xp / hit' : 'Xp / action',
                    actionXp == null ? '—' : _formatXp(actionXp),
                  ),
                ],
              ),
              if (actionXp == null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Train this skill once to estimate actions.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // the skills paid per hit, whose action is an average hit
  bool _isCombatSkill(SkillId id) => const {
    SkillId.HITPOINTS,
    SkillId.ATTACK,
    SkillId.RANGED,
    SkillId.MAGIC,
    SkillId.DEFENCE,
  }.contains(id);

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            unlocked ? Icons.check : Icons.lock,
                            size: 14,
                            color: unlocked ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lv ${unlock.levelRequirement} · ${unlock.name}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (unlock.detail != null)
                                Text(
                                  unlock.detail!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              if (unlock.icons.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                // a set shows every piece it unlocks
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (final icon in unlock.icons)
                                      IconRenderer<Enum>(size: 28, id: icon),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            unlock.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
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

  Widget _buildDebugCard(
    PlayerDataController controller,
    SkillId skillId,
    int level,
  ) {
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
              'DEBUG · SET LEVEL',
              style: TextStyle(fontSize: 10, color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _debugLevelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      // the level standing now, so the field says what it
                      // is about to overwrite
                      hintText: '$level',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    final parsed = int.tryParse(_debugLevelController.text);
                    if (parsed == null) return;
                    controller.debugSetSkillLevel(skillId, parsed);
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

  String _formatCount(int n) {
    final digits = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  String _formatXp(double xp) =>
      xp >= 100 ? xp.round().toString() : xp.toStringAsFixed(1);
}
