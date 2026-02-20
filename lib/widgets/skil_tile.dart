import 'package:flutter/material.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../widgets/icon_renderer.dart';
import '../screens/skill_detail_screen.dart';

class SkillTile extends StatelessWidget {
  const SkillTile({required this.id, super.key, this.size = 100})
    : strokeWidth = size * 0.2;

  final Skills id;

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = SkillController.instance
        .getSkill(id)
        .percentProgressToLevelUp();
    final p = progress.clamp(0.0, 1.0);

    final centerChild = IconRenderer(id: id, size: size * 0.60);

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

                  // Center icon/image (slightly smaller so it doesn't swallow ring)
                  Container(
                    width: size * 0.45,
                    height: size * 0.45,
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
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        children: [
                          centerChild,
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: _CountBadge(
                              count: SkillController.instance
                                  .getSkill(id)
                                  .getLevel(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //  const SizedBox(height: 8),
            /*    Text(
              SkillController.instance.getSkill(id).name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            */
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          //fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
