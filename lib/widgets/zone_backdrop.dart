import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import '../theme/hearth_theme.dart';

/// The zone's art behind the whole list. On arrival it is the full square,
/// uncropped, across the top of the screen, with a dark blur of itself
/// filling the room below. As the list scrolls up over it, the square grows
/// from its foot until it covers the screen, blurring and darkening as it
/// goes, so by the time the header has closed the list floats inside the
/// place rather than under a picture of it. Undrawn art leaves the page.
class ZoneBackdrop extends StatelessWidget {
  const ZoneBackdrop({
    super.key,
    required this.asset,
    required this.scroll,
    required this.growDistance,
  });

  final String asset;
  final ScrollController scroll;

  /// How far the list scrolls before the art has finished growing.
  final double growDistance;

  /// How far the grown art is blurred, and how far it sinks into the page.
  static const double _blur = 8;
  static const double _sink = 0.5;

  Widget _art() => Image.asset(
    asset,
    fit: BoxFit.cover,
    // zone art is pixel art; smoothing it blurs the pixels
    filterQuality: FilterQuality.none,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );

  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) return const SizedBox.shrink();
    final bg = context.palette.bg;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          // grown, the square is as tall as the screen, centred across it
          final grown = math.max(w, h);

          return Stack(
            fit: StackFit.expand,
            children: [
              // below the square at rest: the same scene, blurred and dark
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: _art(),
              ),
              ColoredBox(color: bg.withValues(alpha: 0.6)),

              ListenableBuilder(
                listenable: scroll,
                builder: (context, _) {
                  final offset = scroll.hasClients ? scroll.offset : 0.0;
                  final t = growDistance <= 0
                      ? 1.0
                      : (offset / growDistance).clamp(0.0, 1.0);
                  final size = lerpDouble(w, grown, t)!;
                  Widget art = _art();
                  if (t > 0) {
                    art = ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _blur * t,
                        sigmaY: _blur * t,
                      ),
                      child: art,
                    );
                  }
                  return Stack(
                    children: [
                      Positioned(
                        key: const ValueKey('zone-backdrop'),
                        left: (w - size) / 2,
                        top: 0,
                        width: size,
                        height: size,
                        // the square's foot melts into the blur beneath it,
                        // so the picture has no hard bottom edge
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.transparent],
                            stops: [0.8, 1],
                          ).createShader(rect),
                          child: art,
                        ),
                      ),
                      Positioned.fill(
                        child: ColoredBox(
                          color: bg.withValues(alpha: _sink * t),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
