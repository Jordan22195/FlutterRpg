import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/player_data_controller.dart';
import '../data/skill_data.dart';

class SkillDetailScreen extends StatelessWidget {
  const SkillDetailScreen({super.key, required this.skillId});

  final SkillId skillId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    double levelProgress = controller.getSkillProgress(skillId) * 100;
    levelProgress = levelProgress.roundToDouble();
    return Scaffold(
      appBar: AppBar(title: Text(skillId.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Level : ${controller.getSkillLevel(skillId)}"),
            Text("Total Xp : ${controller.getSkillXp(skillId).round()}"),
            Text(
              "Next Level Xp : ${controller.getNextLevelXp(skillId).round()}",
            ),
            Text(
              "Xp for next level : ${controller.getXpToLevelUp(skillId).round()}",
            ),
            Text("Level Progress: $levelProgress"),
          ],
        ),
      ),
    );
  }
}
