import 'package:flutter/material.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import '../widgets/skil_tile.dart';
import '../data/skill.dart';
import '../screens/skill_detail_screen.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  Widget buildSkillTile(
    BuildContext context,
    PlayerDataController controller,
    Skills skillId,
  ) {
    return SkillTile(
      title: skillId.name,
      progress: controller.getSkill(skillId).percentProgressToLevelUp(),
      icon: Icons.sports_martial_arts,
      size: 70,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SkillDetailScreen(skillId: skillId),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final skills = controller.data?.skills; // Map<Skills, Skill>

    final list = skills?.entries.toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: list?.length,
        itemBuilder: (context, i) {
          final entry = list?[i];
          final skillEnum = entry?.key;
          final skill = entry?.value;

          return buildSkillTile(
            context,
            controller,
            skillEnum ?? Skills.ATTACK,
          );
        },
      ),
    );
  }
}
