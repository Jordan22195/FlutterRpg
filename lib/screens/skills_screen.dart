import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import 'package:provider/provider.dart';
import '../widgets/skil_tile.dart';
import '../data/skill.dart';
import '../screens/skill_detail_screen.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  Widget buildSkillTile(
    BuildContext context,
    PlayerDataController controller,
    SkillId skillId,
  ) {
    return SkillTile(id: skillId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();

    final list = SkillId.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: SkillId.values.length,
        itemBuilder: (context, i) {
          final id = list[i];

          return buildSkillTile(context, controller, id ?? SkillId.ATTACK);
        },
      ),
    );
  }
}
