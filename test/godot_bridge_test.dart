import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massage_flow/godot/godot_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test.godot/methods');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('send serializes an action and payload for Android', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return true;
        });
    final bridge = GodotBridge(methodChannel: channel);

    final accepted = await bridge.send('configure', <String, Object?>{
      'durationSeconds': 300,
    });

    expect(accepted, isTrue);
    expect(receivedCall?.method, 'sendMessage');
    expect(jsonDecode(receivedCall?.arguments as String), <String, Object?>{
      'action': 'configure',
      'payload': <String, Object?>{'durationSeconds': 300},
    });
  });

  test('GodotEvent decodes a JSON payload', () {
    final event = GodotEvent.fromPlatformEvent(<Object?, Object?>{
      'type': 'interaction',
      'payload': '{"count":2}',
    });

    expect(event.type, 'interaction');
    expect(event.payload['count'], 2);
  });
}
