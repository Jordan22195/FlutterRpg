import 'package:flutter/material.dart';
import '../widgets/skil_tile.dart';
import '../data/skill_data.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = SkillId.values.where((s) => s != SkillId.NULL).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) {
          return SkillTile(id: list[i]);
        },
      ),
    );
  }
}
