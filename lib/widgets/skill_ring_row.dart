import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/player_data_controller.dart';
import '../data/skill_data.dart';
import 'overflow_chip.dart';
import 'skil_tile.dart';

/// Compact row of skill progress rings for the skills an activity trains.
/// Shows at most [maxVisible] rings; the rest fold into a +N chip that
/// opens a sheet with the full list. Each ring taps through to its skill.
///
/// Rings shrink to fit the width they are given, so a six-ring row still
/// lands on one line on a narrow phone.
class SkillRingRow extends StatelessWidget {
  const SkillRingRow({
    super.key,
    required this.skills,
    this.maxVisible = 5,
    this.alignment = MainAxisAlignment.center,
  });

  final List<SkillId> skills;
  final int maxVisible;
  final MainAxisAlignment alignment;

  /// The ring size the rows are drawn at when there is room for it.
  static const double _ringSize = 40;

  /// [SkillTile] pads itself by 8 on every side.
  static const double _tilePadding = 16;

  /// Below this the icon inside the ring stops being readable; a row that
  /// still does not fit is better served by the +N chip.
  static const double _minRingSize = 28;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final overflowing = skills.length > maxVisible;
    final visible = overflowing ? skills.sublist(0, maxVisible - 1) : skills;
    final hidden = skills.length - visible.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slots = visible.length + (hidden > 0 ? 1 : 0);
        var ringSize = _ringSize;
        if (constraints.maxWidth.isFinite && slots > 0) {
          final perSlot = constraints.maxWidth / slots - _tilePadding;
          ringSize = min(_ringSize, perSlot).clamp(_minRingSize, _ringSize);
        }

        return Row(
          mainAxisAlignment: alignment,
          children: [
            for (final id in visible)
              SkillTile(id: id, size: ringSize, strokeWidth: ringSize * 0.125),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OverflowChip(
                  count: hidden,
                  size: ringSize,
                  shape: BoxShape.circle,
                  onTap: () => _showAllSkills(context),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAllSkills(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [for (final id in skills) SkillTile(id: id, size: 72)],
          ),
        ),
      ),
    );
  }
}

/// The ring row for an activity screen: the skills the activity itself
/// trains, followed by the three the action loop trains whatever you are
/// doing - stamina drains as you boost, recovery refills it, and the boost
/// trains either speed or strength depending on the stance in play.
class ActivitySkillRingRow extends StatelessWidget {
  const ActivitySkillRingRow({
    super.key,
    required this.skills,
    this.alignment = MainAxisAlignment.center,
  });

  /// What this activity trains on its own - the gathering or crafting skill,
  /// plus hitpoints and defence in combat.
  final List<SkillId> skills;

  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final boostSkill = context.watch<PlayerDataController>().getBoostSkill();

    // a set: an activity that already lists one of the loop skills should
    // not draw it twice
    final all = <SkillId>{
      ...skills,
      SkillId.STAMINA,
      boostSkill,
      SkillId.RECOVERY,
    };

    return SkillRingRow(
      skills: all.toList(),
      // combat trains three of its own, and all six still fit on one line
      maxVisible: 6,
      alignment: alignment,
    );
  }
}
