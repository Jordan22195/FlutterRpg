import 'package:flutter/material.dart';

class SkillTile extends StatelessWidget {
  const SkillTile({
    super.key,
    required this.title,
    required this.progress, // 0..1
    this.icon,
    this.assetImagePath,
    required this.onTap,
    this.size = 92,
    this.strokeWidth = 16,
  });

  final String title;
  final double progress; // 0..1
  final IconData? icon;
  final String? assetImagePath;
  final VoidCallback onTap;

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = progress.clamp(0.0, 1.0);

    final centerChild = (assetImagePath != null)
        ? Image.asset(
            assetImagePath!,
            width: size * 0.42,
            height: size * 0.42,
            fit: BoxFit.contain,
          )
        : Icon(
            icon ?? Icons.auto_awesome,
            size: size * 0.42,
            color: scheme.onSurface,
          );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
                    width: size * 0.60,
                    height: size * 0.60,
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
                    child: centerChild,
                  ),
                ],
              ),
            ),
            //  const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
