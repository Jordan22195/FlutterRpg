import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/item.dart';
import '../controllers/zone_controller.dart';

/// Singleton controller that owns all active buffs and notifies listeners
/// when their remaining durations change.
class BuffController {
  // ---- Singleton boilerplate ----
  static final BuffController instance = BuffController._internal();
  BuffController._internal() {
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _onTick(),
    );
    print("buff controller constructor");
  }

  static PlayerDataController? controller;

  void init(PlayerDataController cont) {
    controller = cont;
  }

  Timer? _timer;

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
      _campfireBuff.expirationTime.add(buff.duration);
      return;
    }

    _campfireBuff = buff;
    print(
      "Set campfire buff: ${buff.name}. Duration: ${buff.duration.inSeconds} seconds.",
    );
  }

  /// Add/refresh a buff.
  /// If it already exists, extends its duration.
  void addBuff(BuffItem buff) {
    if (_activeBuffs.containsKey(buff.id)) {
      _activeBuffs[buff.id]?.expirationTime.add(buff.duration);
      return;
    }
    _activeBuffs[buff.id] = buff;
    print("Added buff: ${buff.name}. Duration: ${buff.duration} seconds.");
  }

  /// Optionally remove a buff early.
  void removeBuff(Items id) {
    if (_activeBuffs.remove(id) != null) {}
  }

  void _onTick() {
    print("Buff Controller on tick ");

    // Decrement campfire buff.
    // If it just expired, normalize the ID to NULL (keeps the name).
    if (_campfireBuff.expirationTime.isBefore(DateTime.now())) {
      _campfireBuff = BuffItem(
        id: Items.NULL,
        skillBonus: _campfireBuff.skillBonus,
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
    if (controller != null) {
      controller?.refresh();
    }
    print("Buff Controller on tick refresh");
  }
}
