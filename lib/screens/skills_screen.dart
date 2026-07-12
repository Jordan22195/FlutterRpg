import 'package:flutter/material.dart';
import '../data/skill_category.dart';
import '../widgets/skill_grid_tile.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          for (final category in SkillCategory.values)
            ..._buildSection(context, category),
        ],
      ),
    );
  }

  List<Widget> _buildSection(BuildContext context, SkillCategory category) {
    final skills = kSkillsByCategory[category] ?? const [];
    if (skills.isEmpty) return const [];
    final scheme = Theme.of(context).colorScheme;
    final accent = skillCategoryColor(category);

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
        child: Row(
          children: [
            Text(
              skillCategoryLabel(category),
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Divider(
                height: 1,
                color: scheme.onSurface.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 96,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: skills.length,
        itemBuilder: (context, i) =>
            SkillGridTile(id: skills[i], accent: accent),
      ),
    ];
  }
}
