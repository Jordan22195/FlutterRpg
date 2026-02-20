import 'package:flutter/material.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../data/skill.dart';
import '../utilities/util.dart';
import 'countdown_timer.dart';

class ObjectCard<T extends Enum> extends StatefulWidget {
  ObjectCard({
    required super.key,
    required this.id,
    required this.count,
    required this.onTap,
    required this.typeId,
    this.height = 60,
    this.expirationTime,
  });

  final T id;
  final int count;
  final VoidCallback onTap;
  final Enum typeId;
  final double height;
  DateTime? expirationTime;

  @override
  State<ObjectCard<T>> createState() => _ObjectCardState<T>();
}

class _ObjectCardState<T extends Enum> extends State<ObjectCard<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // Quick in, slower out.
    _flashOpacity = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 65),
      ],
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant ObjectCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger a subtle flash only when the count increases.
    if (widget.count > oldWidget.count) {
      print(
        'Count increased from ${oldWidget.count} to ${widget.count}, triggering flash.',
      );
      _flashController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  String _cardText() {
    final id = widget.id;
    String cardText = id.toString();

    if (id is Entities) {
      cardText = EntityController.definitionFor(id)?.name ?? id.toString();
    } else if (id is ZoneLocationId) {
      cardText =
          ZoneLocationController.locations[id]?.name.toString() ?? "error";
    }

    return cardText;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Use a higher-contrast container color so the flash is visible on most themes.
    final flashColor = scheme.secondaryContainer.withOpacity(0.35);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Subtle flash overlay.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flashController,
                  builder: (_, __) {
                    return Opacity(
                      opacity: _flashOpacity.value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: flashColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: widget.height,
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Row(
                  children: [
                    ItemStackTile(
                      size: 56,
                      count: widget.count,
                      id: widget.id,
                      showInfoDialogOnTap: false,
                    ),
                    const SizedBox(width: 12),
                    Text(_cardText()),
                    Spacer(),
                    if (widget.expirationTime != null)
                      CountdownTimer(expirationTime: widget.expirationTime!),
                    IconRenderer(size: 45, id: widget.typeId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
