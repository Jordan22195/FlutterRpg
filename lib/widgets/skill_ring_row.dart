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
    this.shrinkWrap = false,
    this.spacing = 6,
  });

  /// The gap between neighbouring rings: 6 in the dock, 14 on a station.
  final double spacing;

  final List<SkillId> skills;
  final int maxVisible;
  final MainAxisAlignment alignment;

  /// Take only the rings' own width rather than the whole row, for a row
  /// sharing its line with something else (the dock's progress bar).
  final bool shrinkWrap;

  /// The ring size the rows are drawn at when there is room for it.
  static const double _ringSize = 40;

  /// [SkillTile]'s own horizontal padding, both sides.
  static final double _tilePadding = SkillTile.padding.horizontal;

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
        // the tiles' own padding already makes a 6pt gap; wider spacing adds
        // the rest between them
        final extraGap = max(0.0, spacing - _tilePadding);
        if (constraints.maxWidth.isFinite && slots > 0) {
          final perSlot =
              (constraints.maxWidth - extraGap * (slots - 1)) / slots -
              _tilePadding;
          ringSize = min(_ringSize, perSlot).clamp(_minRingSize, _ringSize);
        }

        return Row(
          mainAxisAlignment: alignment,
          mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0 && extraGap > 0) SizedBox(width: extraGap),
              SkillTile(
                id: visible[i],
                size: ringSize,
                strokeWidth: ringSize * 0.075,
              ),
            ],
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
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
    this.shrinkWrap = false,
    this.spacing = 6,
  });

  /// See [SkillRingRow.spacing].
  final double spacing;

  /// See [SkillRingRow.shrinkWrap].
  final bool shrinkWrap;

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
      shrinkWrap: shrinkWrap,
      spacing: spacing,
    );
  }
}
