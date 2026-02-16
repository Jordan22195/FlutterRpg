import 'package:flutter/material.dart';
import '../utilities/image_resolver.dart';

class IconRenderer<T extends Enum> extends StatelessWidget {
  const IconRenderer({super.key, required this.size, this.id});

  final double size;

  /// The enum id for this stack (e.g., Items.copperOre, Skills.blacksmithing, etc.)
  final T? id;

  ImageProvider? _resolveImage() {
    final currentId = id;
    if (currentId == null) return null;

    return EnumImageProviderLookup.resolveDynamic(currentId);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImage = _resolveImage();

    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: _IconOrFallback(imageProvider: resolvedImage),
      ),
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
