import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/player_data_controller.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../screens/skill_detail_screen.dart';
import 'icon_renderer.dart';

/// A single skill in the grouped skills grid: a progress ring in the category
/// accent, the skill art and level centred inside it, and the name below.
/// The art renders directly on the surface (no disc/shadow) so pixel sprites
/// stay crisp and the tile reads clean.
class SkillGridTile extends StatelessWidget {
  const SkillGridTile({
    required this.id,
    required this.accent,
    super.key,
    this.ringSize = 58,
  });

  final SkillId id;
  final Color accent;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<PlayerDataController>();
    final progress = controller.getSkillProgress(id).clamp(0.0, 1.0);
    final level = controller.getSkillLevel(id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SkillDetailScreen(skillId: id)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: scheme.onSurface.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconRenderer(id: id, size: ringSize * 0.44),
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            skillLabel(id),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.15,
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
