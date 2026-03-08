class BuffService {
  int getBuffedStatTotal(SkillId id, BuffData buffState) {
    int total = 0;
    for (final buff in buffState.activeBuffs.values) {
      if (buff.skillBonus.containsKey(id)) {
        total += buff.skillBonus[id] ?? 0;
      }
    }
    if (buffState.campfireBuff.skillBonus.containsKey(id)) {
      total += buffState.campfireBuff.skillBonus[id] ?? 0;
    }
    return total;
  }

  /// Set/refresh the campfire buff.
  /// If the same buff is already active, extends its duration.
  void setCampfireBuff(BuffItem buff, BuffData buffState) {
    if (buffState.campfireBuff.id == buff.id) {
      buffState.campfireBuff.expirationTime = buffState
          .campfireBuff
          .expirationTime
          .add(buff.duration);
      return;
    }
  }

  /// Add/refresh a buff.
  /// If it already exists, extends its duration.
  void addBuff(BuffItem buff, BuffData buffState) {
    if (buffState.activeBuffs.containsKey(buff.id)) {
      final existing = buffState.activeBuffs[buff.id];
      if (existing != null) {
        existing.expirationTime = existing.expirationTime.add(buff.duration);
      }
      return;
    }
    buffState.activeBuffs[buff.id] = buff;
    debugPrint(
      "Added buff: ${buff.name}. Duration: ${buff.duration.inSeconds} seconds.",
    );
  }

  /// Optionally remove a buff early.
  void removeBuff(Items id, BuffData buffState) {
    if (buffState.activeBuffs.remove(id) != null) {}
  }

  void checkBuffExpriations(BuffData buffState) {
    checkCampfireBuffExpiration(buffState);
    checkActiveBuffExpiration(buffState);
  }

  // Decrement campfire buff.
  // If it just expired, normalize the ID to NULL (keeps the name).
  void checkCampfireBuffExpiration(BuffData buffState) {
    if (buffState.campfireBuff.expirationTime.isBefore(DateTime.now())) {
      buffState.campfireBuff = BuffItem(
        id: Items.NULL,
        skillBonus: {},
        value: buffState.campfireBuff.value,
        name: buffState.campfireBuff.name,
        duration: Duration.zero,
      );

      //todo - move this out to a system
      ZoneCatalog.removeCampfireFromCurrentZone();
    }
  }

  // Decrement and purge active buffs.
  void checkActiveBuffExpiration(BuffData buffState) {
    if (buffState.activeBuffs.isEmpty) {
      return;
    }
    final ids = buffState.activeBuffs.keys.toList(growable: false);
    for (final id in ids) {
      final buff = buffState.activeBuffs[id];
      if (buff == null) continue;

      if (buff.expirationTime.isBefore(DateTime.now())) {
        buffState.activeBuffs.remove(id);
        continue;
      }
    }
  }
}
