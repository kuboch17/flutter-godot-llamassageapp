import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class GodotEvent {
  const GodotEvent({
    required this.type,
    this.payload = const <String, Object?>{},
  });

  factory GodotEvent.fromPlatformEvent(Object? rawEvent) {
    if (rawEvent is! Map<Object?, Object?>) {
      throw const FormatException('Godot event must be a map.');
    }

    final type = rawEvent['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Godot event is missing its type.');
    }

    final payloadJson = rawEvent['payload'];
    if (payloadJson == null || payloadJson == '') {
      return GodotEvent(type: type);
    }
    if (payloadJson is! String) {
      throw const FormatException('Godot event payload must be JSON.');
    }

    final decoded = jsonDecode(payloadJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Godot event payload must be a JSON object.');
    }
    return GodotEvent(type: type, payload: decoded);
  }

  final String type;
  final Map<String, Object?> payload;
}

class GodotBridge {
  GodotBridge({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('dev.massageflow/godot_methods'),
      _eventChannel =
          eventChannel ?? const EventChannel('dev.massageflow/godot_events');

  static final GodotBridge instance = GodotBridge();

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<GodotEvent>? _events;

  Stream<GodotEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .map<GodotEvent>(GodotEvent.fromPlatformEvent)
      .asBroadcastStream();

  Future<bool> send(
    String action, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) async {
    final accepted = await _methodChannel.invokeMethod<bool>(
      'sendMessage',
      jsonEncode(<String, Object?>{'action': action, 'payload': payload}),
    );
    return accepted ?? false;
  }

  Future<bool> isEngineReady() async {
    return await _methodChannel.invokeMethod<bool>('isEngineReady') ?? false;
  }
}
