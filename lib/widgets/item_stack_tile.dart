import 'package:flutter/material.dart';
import '../utilities/image_resolver.dart';

class ItemStackTile<T extends Enum> extends StatelessWidget {
  const ItemStackTile({
    super.key,
    required this.size,
    this.id,
    required this.count,
    this.onTap,
    this.showInfoDialogOnTap = false,
    this.title,
    this.description,
  });

  final double size;

  /// The enum id for this stack (e.g., Items.copperOre, Skills.blacksmithing, etc.)
  final T? id;

  final int count;

  final VoidCallback? onTap;

  final bool showInfoDialogOnTap;
  final String? title;
  final String? description;

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title ?? 'Item'),
        content: Text(description ?? 'No description.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImage() {
    final currentId = id;
    if (currentId == null) return null;

    return EnumImageProviderLookup.resolveDynamic(currentId);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImage = _resolveImage();

    final child = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background + icon
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _IconOrFallback(imageProvider: resolvedImage),
              ),
            ),
          ),

          // Count badge
          Positioned(right: 4, bottom: 4, child: _CountBadge(count: count)),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap:
          onTap ??
          (showInfoDialogOnTap ? () => _showInfoDialog(context) : null),
      child: child,
    );
  }
}

class _IconOrFallback extends StatelessWidget {
  const _IconOrFallback({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    if (imageProvider == null) {
      return const Center(child: Icon(Icons.help_outline));
    }

    return Image(
      image: imageProvider!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // nice for pixel art
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
