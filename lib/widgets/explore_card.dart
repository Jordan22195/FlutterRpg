import 'package:flutter/material.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import '../data/skill_data.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../utilities/util.dart';
import 'countdown_timer.dart';
import 'list_row.dart';
import 'sprite_frame.dart';

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

/// A place or an entity in a zone's list, on the shared [ListRow].
///
/// Places (stations, shops, dungeons, fishing spots) end in a chevron and
/// say what they train; entities found by exploring say how hard they are
/// and how many are standing ("Lv 3 · 1.57k"), and end in the xp the stack
/// is worth.
class ObjectCard<T extends Enum> extends StatefulWidget {
  const ObjectCard({
    required super.key,
    required this.id,
    required this.count,
    required this.onTap,
    required this.typeId,
    required this.kind,
    this.onIconTap,
    this.typeIds,
    this.name,
    this.expirationTime,
    this.subtitle,
    this.statLevel,
    this.xpPerUnit,
    this.isStructure = false,
    this.locked = false,
    this.requiredLevel = 0,
  });

  final T id;
  final int count;
  final VoidCallback onTap;

  /// What the sprite frame is tinted as.
  final SpriteKind kind;

  /// Tapping the entity's portrait, rather than the card body. Used for
  /// the details popup, so the card itself still opens the entity screen.
  final VoidCallback? onIconTap;

  /// The skill this entity trains (drives the meta icon/label). For
  /// structures without a skill (shops, dungeons) pass the entity id and
  /// set [subtitle].
  final Enum typeId;

  /// Every skill the entity currently offers, when that is more than one —
  /// a firepit burning a cookfire trains firemaking and cooking both. Falls
  /// back to `[typeId]`, which is what all single-skill callers get.
  final List<Enum>? typeIds;

  final String? name;

  /// Campfires: burn-out countdown shown in the trailing slot.
  final DateTime? expirationTime;

  /// Overrides a place's meta text (skill name), e.g. "Shop" / "Dungeon".
  final String? subtitle;

  /// How hard the entity is: a combat entity's level, a gathering node's
  /// defence. Shown as "Lv N". Null for structures with no such number.
  final int? statLevel;

  /// Estimated xp for consuming one count. Non-null shows the trailing
  /// xp column (total stack xp + per-action rate).
  final double? xpPerUnit;

  /// Permanent zone entities (stations, shops, dungeons) end in a chevron
  /// instead of counts/xp.
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

  Widget _buildMeta(BuildContext context) {
    if (widget.locked) {
      return RowMeta(
        icons: [
          Icon(Icons.lock_outline, size: 14, color: context.palette.textMuted),
        ],
        text:
            "Requires ${skillDisplayName(widget.typeId)} "
            "${widget.requiredLevel}",
      );
    }

    final level = widget.statLevel;

    // an entity says how hard it is and how many are standing; the frame's
    // tint and the list's chip already say what kind of thing it is
    if (!widget.isStructure) {
      return RowMeta(
        text: [
          if (level != null) 'Lv $level',
          Util.formatShortCount(widget.count),
        ].join(' · '),
      );
    }

    final types = widget.typeIds ?? [widget.typeId];
    final skills = types
        .where((t) => t is SkillId && t != SkillId.NULL)
        .toList();
    final label = widget.subtitle ?? types.map(skillDisplayName).join(' · ');

    // a place says what it trains, and how hard it is when it has a number
    return RowMeta(
      icons: [for (final skill in skills) IconRenderer(size: 14, id: skill)],
      text: level != null ? '$label · Lv $level' : label,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final palette = context.palette;

    if (widget.expirationTime != null) {
      return CountdownTimer(expirationTime: widget.expirationTime!);
    }

    final xp = widget.xpPerUnit;
    if (xp != null && !widget.locked) {
      final total = xp * widget.count;
      final xpColor = context.gameColors.xp;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text.rich(
            TextSpan(
              text: _formatXp(total),
              style: HearthText.xpValue.copyWith(color: xpColor),
              children: [
                TextSpan(
                  text: " xp",
                  style: HearthText.xpSuffix.copyWith(color: xpColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "+${_formatXp(xp)} / ${skillActionVerb(widget.typeId)}",
            style: HearthText.rowMeta.copyWith(color: palette.textMuted),
          ),
        ],
      );
    }

    return RowChevron(dimmed: widget.locked);
  }

  @override
  Widget build(BuildContext context) {
    // a used-up resource node reads like a locked one. structures carry no
    // count at all (they pass 0), so they are never depleted.
    final depleted = !widget.isStructure && !widget.locked && widget.count <= 0;
    final flashColor = context.palette.raised;

    final row = ListRow(
      height: widget.isStructure ? ListRow.placeHeight : ListRow.entityHeight,
      onTap: widget.onTap,
      leading: SpriteFrame(
        id: widget.id,
        kind: widget.kind,
        size: widget.isStructure ? 48 : 52,
        spriteSize: widget.isStructure ? 38 : 40,
        depleted: depleted,
        onTap: widget.onIconTap,
        // the sprite sits on the card's own colour; the frame's border
        // still says what kind of thing it is
        fill: context.palette.surface,
      ),
      title: widget.name ?? widget.id.name,
      meta: _buildMeta(context),
      trailing: _buildTrailing(context),
      // a subtle flash when the stack grows
      overlay: AnimatedBuilder(
        animation: _flashController,
        builder: (_, _) => Opacity(
          opacity: _flashOpacity.value,
          child: ColoredBox(color: flashColor),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: widget.locked || depleted
          ? Opacity(opacity: 0.55, child: row)
          : row,
    );
  }
}
