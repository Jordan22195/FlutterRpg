import 'package:flutter/material.dart';
import 'package:rpg/catalogs/items/items.dart';

/// A gem-set piece drawn from layers: the empty gold [JewellerySetting]
/// sprite, with the greyscale [GemCut] overlay tinted in the gem's colour
/// on top. Eight sprites cover all 84 pieces.
///
/// The overlay square is placed in the base's own source pixels (see
/// [JewellerySetting.overlayLeft]), scaled to whatever size the icon is
/// drawn at, so the stone stays seated in its socket at every size.
class JewelleryIcon extends StatelessWidget {
  const JewelleryIcon({super.key, required this.definition});

  final JewelleryDefinition definition;

  /// The icon for [id], or null when it is not gem-set jewellery.
  static JewelleryIcon? forId(Enum id) {
    if (id is! ItemId) return null;
    final def = id.definition;
    return def is JewelleryDefinition ? JewelleryIcon(definition: def) : null;
  }

  @override
  Widget build(BuildContext context) {
    final setting = definition.setting;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale =
              constraints.biggest.shortestSide / JewellerySetting.baseSize;
          return Stack(
            children: [
              Positioned.fill(child: _sprite(setting.baseAsset)),
              Positioned(
                left: setting.overlayLeft * scale,
                top: setting.overlayTop * scale,
                width: setting.overlaySize * scale,
                height: setting.overlaySize * scale,
                // modulate multiplies the gem colour into the greyscale
                // stone: white facets become the colour, grey ones its
                // shades, and the transparent edge stays clear
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    definition.gem.color,
                    BlendMode.modulate,
                  ),
                  child: _sprite(definition.cut.overlayAsset),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _sprite(String asset) => Image.asset(
    asset,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.none, // pixel art
    errorBuilder: (_, _, _) =>
        const Center(child: Icon(Icons.broken_image_outlined)),
  );
}
