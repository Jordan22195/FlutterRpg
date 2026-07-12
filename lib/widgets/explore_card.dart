import 'package:flutter/material.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../data/skill_data.dart';
import 'countdown_timer.dart';

/// Human label for a skill on explore cards ("Combat", "Woodcutting").
String skillDisplayName(Enum skill) {
  if (skill == SkillId.ATTACK) return "Combat";
  final raw = skill.name;
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
}

/// Action verb for a skill's per-unit xp readout ("+16 / kill").
String skillActionVerb(Enum skill) {
  switch (skill) {
    case SkillId.ATTACK:
      return "kill";
    case SkillId.FISHING:
      return "catch";
    case SkillId.HERBALISM:
      return "pick";
    case SkillId.WOODCUTTING:
      return "chop";
    case SkillId.MINING:
      return "mine";
    default:
      return "action";
  }
}

class ObjectCard<T extends Enum> extends StatefulWidget {
  const ObjectCard({
    required super.key,
    required this.id,
    required this.count,
    required this.onTap,
    required this.typeId,
    this.name,
    this.height = 64,
    this.expirationTime,
    this.subtitle,
    this.xpPerUnit,
    this.isStructure = false,
    this.locked = false,
    this.requiredLevel = 0,
  });

  final T id;
  final int count;
  final VoidCallback onTap;

  /// The skill this entity trains (drives the subtitle icon/label). For
  /// structures without a skill (shops, dungeons) pass the entity id and
  /// set [subtitle].
  final Enum typeId;
  final String? name;
  final double height;

  /// Campfires: burn-out countdown shown in the trailing slot.
  final DateTime? expirationTime;

  /// Overrides the default subtitle (skill name), e.g. "Shop" / "Dungeon".
  final String? subtitle;

  /// Estimated xp for consuming one count. Non-null shows the trailing
  /// xp column (total stack xp + per-action rate).
  final double? xpPerUnit;

  /// Permanent zone entities (stations, shops, dungeons) get an accent
  /// stripe and a chevron instead of counts/xp.
  final bool isStructure;

  /// Level-gated entities render dimmed with the requirement.
  final bool locked;
  final int requiredLevel;

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
      _flashController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  String _cardText() {
    return widget.name ?? widget.id.name;
  }

  static String _formatXp(double xp) {
    final rounded = xp.round();
    final text = '$rounded';
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  Widget _buildSubtitle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withOpacity(0.6),
    );

    if (widget.locked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: style?.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              "Requires ${skillDisplayName(widget.typeId)} "
              "${widget.requiredLevel}",
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.typeId is SkillId && widget.typeId != SkillId.NULL) ...[
          IconRenderer(size: 16, id: widget.typeId),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            widget.subtitle ?? skillDisplayName(widget.typeId),
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.expirationTime != null) {
      return CountdownTimer(expirationTime: widget.expirationTime!);
    }

    final xp = widget.xpPerUnit;
    if (xp != null && !widget.locked) {
      final total = xp * widget.count;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text.rich(
            TextSpan(
              text: _formatXp(total),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: " xp",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.tertiary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "+${_formatXp(xp)} / ${skillActionVerb(widget.typeId)}",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      );
    }

    return Icon(
      Icons.chevron_right,
      color: scheme.onSurface.withOpacity(widget.locked ? 0.25 : 0.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Use a higher-contrast container color so the flash is visible on most themes.
    final flashColor = scheme.secondaryContainer.withOpacity(0.35);

    final card = Card(
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
                  builder: (_, _) {
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

            // Accent stripe marking permanent structures.
            if (widget.isStructure)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: scheme.primary),
              ),

            SizedBox(
              width: double.infinity,
              height: widget.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ItemStackTile(
                      size: 52,
                      count: widget.locked ? 0 : widget.count,
                      id: widget.id,
                      showInfoDialogOnTap: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cardText(),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _buildSubtitle(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrailing(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return widget.locked ? Opacity(opacity: 0.55, child: card) : card;
  }
}
