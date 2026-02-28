import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/skill.dart';
import '../controllers/player_data_controller.dart';

class SkillDetailScreen extends StatelessWidget {
  const SkillDetailScreen({super.key, required this.skillId});

  final Skills skillId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final skill = SkillController.instance.getSkill(skillId);
    double levelProgress = skill.percentProgressToLevelUp() * 100;
    levelProgress = levelProgress.roundToDouble();
    return Scaffold(
      appBar: AppBar(title: Text(skillId.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Level : ${skill.getLevel()}"),
            Text("Total Xp : ${skill.xp.round()}"),
            Text("Next Level Xp : ${skill.nextLevelXp().round()}"),
            Text("Xp for next level : ${skill.xpToLevelUp().round()}"),
            Text("Level Progress: ${levelProgress}"),
          ],
        ),
      ),
    );
  }
}
