import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/buff_data.dart';
import '../services/buff_service.dart';

class BuffController extends ChangeNotifier {
  // ---- Singleton boilerplate ----
  final BuffData _buffState;
  final BuffService _buffService;

  BuffController({
    required BuffData buffState,
    required BuffService buffService,
  }) : _buffState = buffState,
       _buffService = buffService {
    Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    _buffService.checkBuffExpriations(_buffState);

    // Always notify once per tick so UI countdowns update.
    notifyListeners();
  }
}
