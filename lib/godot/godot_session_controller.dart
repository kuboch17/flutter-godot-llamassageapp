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
  Map<String, Object?> _configuration = const {};
  bool get active => _active;
  bool get ready => _ready;

  void preload() {
    _subscription ??= GodotBridge.instance.events.listen(
      (event) {
        if (event.type == 'engine_ready') {
          // Reconnect after a Flutter hot restart with a retained native engine.
          if (!_active) unawaited(_send('stop_session'));
          unawaited(_send('ping'));
        } else if (event.type == 'godot_ready' && !_ready) {
          _ready = true;
          notifyListeners();
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
      await GodotBridge.instance.send(
        action,
        action == 'start_session' ? _configuration : const {},
      );
    } catch (_) {
      _ready = false;
    }
  }

  void open({int durationMinutes = 5, List<String> bodyParts = const []}) {
    _configuration = {
      'duration_seconds': durationMinutes * 60,
      'body_parts': List<String>.of(bodyParts),
    };
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
