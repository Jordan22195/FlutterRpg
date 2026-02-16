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
    return SkillTile(id: skillId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();

    final list = Skills.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: Skills.values.length,
        itemBuilder: (context, i) {
          final id = list[i];

          return buildSkillTile(context, controller, id ?? Skills.ATTACK);
        },
      ),
    );
  }
}
