import 'package:flutter/material.dart';
import '../data/skill_data.dart';
import 'overflow_chip.dart';
import 'skil_tile.dart';

/// Compact row of skill progress rings for the skills an activity trains.
/// Shows at most [maxVisible] rings; the rest fold into a +N chip that
/// opens a sheet with the full list. Each ring taps through to its skill.
class SkillRingRow extends StatelessWidget {
  const SkillRingRow({
    super.key,
    required this.skills,
    this.maxVisible = 5,
    this.alignment = MainAxisAlignment.start,
  });

  final List<SkillId> skills;
  final int maxVisible;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final overflowing = skills.length > maxVisible;
    final visible = overflowing ? skills.sublist(0, maxVisible - 1) : skills;
    final hidden = skills.length - visible.length;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        for (final id in visible) SkillTile(id: id, size: 40, strokeWidth: 5),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: OverflowChip(
              count: hidden,
              size: 40,
              shape: BoxShape.circle,
              onTap: () => _showAllSkills(context),
            ),
          ),
      ],
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
