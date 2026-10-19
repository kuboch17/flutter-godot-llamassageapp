import 'dart:async';

import 'package:flutter/foundation.dart';

import 'godot_bridge.dart';

/// Keeps the engine warm while each visit creates a fresh massage scene.
class GodotSessionController extends ChangeNotifier {
  GodotSessionController._();
  static final instance = GodotSessionController._();

  StreamSubscription<GodotEvent>? _subscription;
  bool _ready = false;
  bool _active = false;
  bool get active => _active;

  void preload() {
    _subscription ??= GodotBridge.instance.events.listen(
      (event) {
        if (event.type == 'engine_ready') {
          // Reconnect after a Flutter hot restart with a retained native engine.
          if (!_active) unawaited(_send('stop_session'));
          unawaited(_send('ping'));
        } else if (event.type == 'godot_ready' && !_ready) {
          _ready = true;
          if (_active) unawaited(_send('start_session'));
        }
      },
      onError: (_) {
        _ready = false;
      },
    );
  }

  Future<void> _send(String action) async {
    try {
      await GodotBridge.instance.send(action);
    } catch (_) {
      _ready = false;
    }
  }

  void open() {
    _active = true;
    notifyListeners();
    if (_ready) unawaited(_send('start_session'));
  }

  void close() {
    _active = false;
    notifyListeners();
    if (_ready) unawaited(_send('stop_session'));
  }
}
