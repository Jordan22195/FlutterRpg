import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/data/skill_data.dart';
import '../controllers/player_data_controller.dart';
import '../widgets/icon_renderer.dart';
import '../screens/skill_detail_screen.dart';

class SkillTile extends StatelessWidget {
  const SkillTile({
    required this.id,
    super.key,
    this.size = 100,
    double? strokeWidth,
  }) : strokeWidth = strokeWidth ?? size * 0.2;

  final SkillId id;

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<PlayerDataController>();
    final progress = controller.getSkillProgress(id);
    final p = progress.clamp(0.0, 1.0);

    // Size the inner disc to sit just inside the ring (leaving a hair of
    // gap), rather than a fixed fraction of the ring. This lets the skill
    // icon fill the whole ring hole, so it stays legible even on the
    // compact 40px rings in the encounter/explore screens.
    final innerDiameter = (size - 2 * strokeWidth - size * 0.06).clamp(
      size * 0.4,
      size,
    );
    final centerChild = IconRenderer(id: id, size: innerDiameter * 0.86);

    return InkWell(
      borderRadius: BorderRadius.circular(210),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SkillDetailScreen(skillId: id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ✅ One progress indicator: visible track + visible fill
                  CircularProgressIndicator(
                    value: p,
                    strokeWidth: strokeWidth,
                    strokeCap: StrokeCap.butt,
                    backgroundColor: scheme.onSurface.withOpacity(0.14),
                    color: scheme.primary,
                  ),

                  // Center icon/image, sized to fill the ring hole
                  Container(
                    width: innerDiameter,
                    height: innerDiameter,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.12),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        centerChild,
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _CountBadge(
                            count: controller.getSkillLevel(id),
                            // scales down for compact rings
                            fontSize: max(10, size * 0.14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.fontSize = 14});

  final int count;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          //fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
