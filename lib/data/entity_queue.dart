import '../catalogs/entity_catalog.dart';

/// An ordered run of entities worked through one at a time — the thing a
/// dungeon card holds, and the shape any future "do these in order" content
/// can reuse.
///
/// A member carries its own count, so "five goblins" is one member with
/// `count: 5` rather than five members. The queue advances only when a
/// member is fully spent, which is what lets the action loop run straight
/// through a card without the player re-pressing anything.
class EntityQueue {
  final String name;
  final List<EncounterEntity> members;

  /// Position in [members]. Equal to `members.length` once the queue is
  /// cleared.
  int index;

  EntityQueue({required this.name, required this.members, this.index = 0});

  /// The member being worked right now; null once the queue is cleared.
  EncounterEntity? get current =>
      index >= 0 && index < members.length ? members[index] : null;

  /// The members still waiting behind [current], in queue order.
  List<EncounterEntity> get remaining =>
      index + 1 < members.length ? members.sublist(index + 1) : const [];

  bool get cleared => index >= members.length;

  /// What the encounter screen should show: the live member, or the last
  /// one once the queue is cleared — a spent card keeps its final entity on
  /// screen instead of blanking the moment it dies.
  EncounterEntity? get displayed =>
      current ?? (members.isEmpty ? null : members.last);

  /// Moves to the next member and returns it, or null when that clears the
  /// queue.
  EncounterEntity? advance() {
    if (index < members.length) index++;
    return current;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'index': index,
      'members': members.map((m) => m.toJson()).toList(),
    };
  }

  factory EntityQueue.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = <EncounterEntity>[];
    if (rawMembers is List) {
      for (final raw in rawMembers) {
        if (raw is! Map<String, dynamic>) continue;
        final entity = Entity.fromJson(raw);
        if (entity is EncounterEntity) members.add(entity);
      }
    }

    final rawIndex = json['index'];
    final index = rawIndex is int ? rawIndex : 0;

    return EntityQueue(
      name: json['name'] is String ? json['name'] as String : '',
      members: members,
      // a member that failed to parse would otherwise leave the queue
      // pointing past its own list
      index: index.clamp(0, members.length),
    );
  }
}
