import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/data/skill_data.dart';
import '../controllers/player_data_controller.dart';
import '../data/skill_category.dart';
import '../screens/skill_detail_screen.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../utilities/shell_page_route.dart';

/// A skill's level ring: a disc in the palette's surface with the level in
/// the middle and the progress to the next level drawn around it in the
/// skill's own colour, from 12 o'clock. A maxed skill closes the ring.
///
/// The number is the whole face — no icon — so a row of rings reads as a
/// row of levels, with the colour saying which is which. Taps through to
/// the skill.
class SkillTile extends StatelessWidget {
  const SkillTile({
    required this.id,
    super.key,
    this.size = 40,
    double? strokeWidth,
  }) : strokeWidth = strokeWidth ?? size * 0.075;

  final SkillId id;

  final double size;
  final double strokeWidth;

  /// Room around the ring, so a 40px ring still has a 44pt-tall tap target
  /// and neighbouring rings sit 6pt apart.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 3,
    vertical: 2,
  );

  /// The skill's name as a person would say it ("Stamina").
  static String spokenName(SkillId id) {
    final raw = id.name;
    if (raw.isEmpty) return raw;
    return raw[0] + raw.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = context.watch<PlayerDataController>();
    final progress = controller.getSkillProgress(id).clamp(0.0, 1.0);
    final level = controller.getSkillLevel(id);

    return Semantics(
      button: true,
      label: '${spokenName(id)}, level $level',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Navigator.of(context).push(
            ShellPageRoute(builder: (_) => SkillDetailScreen(skillId: id)),
          );
        },
        child: Padding(
          padding: padding,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: SkillRingPainter(
                progress: progress,
                color: skillRingColor(id),
                track: palette.borderStrong,
                fill: palette.surface,
                strokeWidth: strokeWidth,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(strokeWidth + 2),
                    child: Text(
                      '$level',
                      style: HearthText.ringNumber.copyWith(
                        color: palette.text,
                        // 13 on the standard 40px ring, scaling with it
                        fontSize: max(10, size * 0.325),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a level ring: the disc, a track, and [progress] of the circle
/// from 12 o'clock with round ends. Full progress draws a closed ring.
class SkillRingPainter extends CustomPainter {
  const SkillRingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.fill,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color track;
  final Color fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    // the stroke sits a little inside the disc's edge: radius 17 on a 40 disc
    final radius = outer * 0.85;

    canvas.drawCircle(center, outer, Paint()..color = fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (progress >= 1.0) {
      canvas.drawCircle(center, radius, stroke..color = color);
      return;
    }

    canvas.drawCircle(center, radius, stroke..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      stroke
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(SkillRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}
