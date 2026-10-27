/// One save slot as the save selector lists it. The save itself lives in its
/// own file; this is only what the list needs without opening every save.
class SaveSlotInfo {
  final String id;
  String name;
  DateTime createdAt;

  /// The player's own short label for this save ("Ironman", "Alt"), shown
  /// beside its name. Empty when the save has none.
  String tag;

  /// Longest tag the player can set, so it stays a label and not a title.
  static const int maxTagLength = 16;

  /// When this slot's save was last written, or null if it never has been.
  DateTime? lastPlayed;

  /// Sum of every skill's earned level as of [lastPlayed], uncapped.
  int totalLevel;

  SaveSlotInfo({
    required this.id,
    required this.name,
    this.tag = '',
    DateTime? createdAt,
    this.lastPlayed,
    this.totalLevel = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (tag.isNotEmpty) 'tag': tag,
      'createdAt': createdAt.toIso8601String(),
      if (lastPlayed != null) 'lastPlayed': lastPlayed!.toIso8601String(),
      'totalLevel': totalLevel,
    };
  }

  factory SaveSlotInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! String || rawId.isEmpty) {
      throw FormatException('SaveSlotInfo.id is missing or invalid.');
    }
    final rawName = json['name'];
    final rawCreated = json['createdAt'];
    final rawLastPlayed = json['lastPlayed'];
    final rawTotal = json['totalLevel'];

    return SaveSlotInfo(
      id: rawId,
      name: rawName is String && rawName.isNotEmpty ? rawName : rawId,
      tag: json['tag'] is String ? json['tag'] as String : '',
      createdAt: rawCreated is String ? DateTime.tryParse(rawCreated) : null,
      lastPlayed: rawLastPlayed is String
          ? DateTime.tryParse(rawLastPlayed)
          : null,
      totalLevel: rawTotal is int ? rawTotal : 0,
    );
  }
}

/// Every save slot on the device and which one the app opens on.
class SaveSlotIndex {
  String activeSlotId;
  final List<SaveSlotInfo> slots;

  SaveSlotIndex({required this.activeSlotId, required this.slots});

  /// The index for a device with a single save in [slotId].
  factory SaveSlotIndex.single(String slotId) => SaveSlotIndex(
    activeSlotId: slotId,
    slots: [SaveSlotInfo(id: slotId, name: 'Save 1')],
  );

  SaveSlotInfo? slot(String id) {
    for (final s in slots) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The first `slot_N` id no slot has taken yet.
  String nextSlotId() {
    for (var n = slots.length + 1; ; n++) {
      final id = 'slot_$n';
      if (slot(id) == null) return id;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'activeSlotId': activeSlotId,
      'slots': [for (final s in slots) s.toJson()],
    };
  }

  factory SaveSlotIndex.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'];
    if (rawSlots is! List) {
      throw FormatException('SaveSlotIndex.slots is missing or invalid.');
    }
    final slots = [
      for (final raw in rawSlots.whereType<Map<String, dynamic>>())
        SaveSlotInfo.fromJson(raw),
    ];
    if (slots.isEmpty) {
      throw FormatException('SaveSlotIndex has no slots.');
    }

    // an active id that names no slot opens the first one instead
    final rawActive = json['activeSlotId'];
    final active = rawActive is String && slots.any((s) => s.id == rawActive)
        ? rawActive
        : slots.first.id;
    return SaveSlotIndex(activeSlotId: active, slots: slots);
  }
}
