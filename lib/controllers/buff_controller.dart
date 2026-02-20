import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';
import '../controllers/zone_controller.dart';

/// Singleton controller that owns all active buffs and notifies listeners
/// when their remaining durations change.
class BuffController extends ChangeNotifier {
  // ---- Singleton boilerplate ----

  static final BuffController instance = BuffController._internal();
  BuffController._internal() {
    Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  static PlayerDataController? controller;

  void init(PlayerDataController cont) {
    controller = cont;
  }

  int getBuffedStatTotal(Skills id) {
    int total = 0;
    for (final buff in _activeBuffs.values) {
      if (buff.skillBonus.containsKey(id)) {
        total += buff.skillBonus[id] ?? 0;
      }
    }
    if (_campfireBuff.skillBonus.containsKey(id)) {
      total += _campfireBuff.skillBonus[id] ?? 0;
    }
    return total;
  }

  // ---- Buff state ----
  final Map<Items, BuffItem> _activeBuffs = {};

  BuffItem _campfireBuff = BuffItem(
    id: Items.NULL,
    skillBonus: {},
    value: 0,
    name: "Campfire Warmth",
    duration: Duration.zero,
  );

  Map<Items, BuffItem> get activeBuffs => Map.unmodifiable(_activeBuffs);
  BuffItem get campfireBuff => _campfireBuff;

  /// Set/refresh the campfire buff.
  /// If the same buff is already active, extends its duration.
  void setCampfireBuff(BuffItem buff) {
    if (_campfireBuff.id == buff.id) {
      _campfireBuff.expirationTime = _campfireBuff.expirationTime.add(
        buff.duration,
      );
      return;
    }

    _campfireBuff = buff;
    debugPrint(
      "Set campfire buff: ${buff.name}. Duration: ${buff.duration.inSeconds} seconds.",
    );
  }

  /// Add/refresh a buff.
  /// If it already exists, extends its duration.
  void addBuff(BuffItem buff) {
    if (_activeBuffs.containsKey(buff.id)) {
      final existing = _activeBuffs[buff.id];
      if (existing != null) {
        existing.expirationTime = existing.expirationTime.add(buff.duration);
      }
      return;
    }
    _activeBuffs[buff.id] = buff;
    debugPrint(
      "Added buff: ${buff.name}. Duration: ${buff.duration.inSeconds} seconds.",
    );
  }

  /// Optionally remove a buff early.
  void removeBuff(Items id) {
    if (_activeBuffs.remove(id) != null) {}
  }

  void _onTick() {
    // Decrement campfire buff.
    // If it just expired, normalize the ID to NULL (keeps the name).
    if (_campfireBuff.expirationTime.isBefore(DateTime.now())) {
      _campfireBuff = BuffItem(
        id: Items.NULL,
        skillBonus: {},
        value: _campfireBuff.value,
        name: _campfireBuff.name,
        duration: Duration.zero,
      );
      ZoneController.removeCampfireFromCurrentZone();
    }

    // Decrement and purge active buffs.
    if (_activeBuffs.isNotEmpty) {
      final ids = _activeBuffs.keys.toList(growable: false);
      for (final id in ids) {
        final buff = _activeBuffs[id];
        if (buff == null) continue;

        if (buff.duration <= Duration.zero) {
          _activeBuffs.remove(id);
          continue;
        }

        final next = buff.duration - const Duration(seconds: 1);
        buff.duration = next.isNegative ? Duration.zero : next;

        if (buff.duration == Duration.zero) {
          _activeBuffs.remove(id);
        }
      }
    }

    // Always notify once per tick so UI countdowns update.
    notifyListeners();
  }
}
