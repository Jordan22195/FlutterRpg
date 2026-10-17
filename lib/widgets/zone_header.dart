import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hearth_theme.dart';
import 'art_header.dart';

/// The explore screen's header: the zone's art from the top of the screen,
/// with the status row over its top and the back button, the zone's name
/// and its difficulty over its foot. Scrolling the list collapses it into a
/// strip (see [ArtHeader]), so the art never costs the list any room it
/// needs.
///
/// Several zones name art that hasn't been drawn yet, so the header opens
/// collapsed and only grows to the picture once it has actually loaded.
/// Which paths turned out to have art is remembered, so coming back to a
/// zone opens straight onto its art.
class ZoneHeader extends StatefulWidget {
  const ZoneHeader({
    super.key,
    required this.name,
    required this.iconAsset,
    required this.zoneLevel,
  });

  final String name;
  final String iconAsset;

  /// The zone's Exploration difficulty; 0 shows no badge.
  final int zoneLevel;

  /// Width / height of each art path that loaded, or null for a path with
  /// no file behind it. Only whether there is a ratio matters now that the
  /// art is cropped to the header, but the ratio costs nothing to keep.
  static final Map<String, double?> _aspectRatios = {};

  @override
  State<ZoneHeader> createState() => _ZoneHeaderState();
}

class _ZoneHeaderState extends State<ZoneHeader> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _subscribing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ZoneHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconAsset != widget.iconAsset) _resolve();
  }

  void _resolve() {
    _unlisten();
    final path = widget.iconAsset;
    if (path.isEmpty || ZoneHeader._aspectRatios.containsKey(path)) return;

    _stream = AssetImage(path).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, _) {
        ZoneHeader._aspectRatios[path] = info.image.width / info.image.height;
        _unlisten();
        // a cached image answers inside addListener, mid-build, where the
        // build already under way picks the ratio up without a setState
        if (mounted && !_subscribing) setState(() {});
      },
      // undrawn art: stay a title bar
      onError: (_, _) {
        ZoneHeader._aspectRatios[path] = null;
        _unlisten();
      },
    );
    _subscribing = true;
    _stream!.addListener(_listener!);
    _subscribing = false;
  }

  void _unlisten() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _unlisten();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // undrawn art (or none at all) opens straight onto the collapsed bar
    final hasArt = ZoneHeader._aspectRatios[widget.iconAsset] != null;
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ZoneHeaderDelegate(
        name: widget.name,
        iconAsset: hasArt ? widget.iconAsset : null,
        zoneLevel: widget.zoneLevel,
        minHeight: ArtHeader.collapsedHeight(topPadding),
        maxHeight: hasArt
            ? math.max(
                ArtHeader.expandedHeight,
                ArtHeader.collapsedHeight(topPadding),
              )
            : ArtHeader.collapsedHeight(topPadding),
      ),
    );
  }
}

class _ZoneHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ZoneHeaderDelegate({
    required this.name,
    required this.iconAsset,
    required this.zoneLevel,
    required this.minHeight,
    required this.maxHeight,
  });

  final String name;
  final String? iconAsset;
  final int zoneLevel;
  final double minHeight;
  final double maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxHeight - minHeight;
    final collapse = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    return ArtHeader(
      title: name,
      collapse: collapse,
      artAsset: iconAsset,
      trailing: zoneLevel > 0
          ? ArtHeaderChip(
              icon: Icon(
                Icons.explore_outlined,
                size: 16,
                color: context.gameColors.exploration,
              ),
              label: '$zoneLevel',
              semanticsLabel: 'Zone exploration level $zoneLevel',
            )
          : null,
    );
  }

  @override
  bool shouldRebuild(_ZoneHeaderDelegate old) =>
      old.name != name ||
      old.iconAsset != iconAsset ||
      old.zoneLevel != zoneLevel ||
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight;
}
