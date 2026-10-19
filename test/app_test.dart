import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massage_flow/app.dart';
import 'package:massage_flow/godot/godot_view.dart';

void main() {
  testWidgets('opens fullscreen landscape massage and returns to the menu', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final displayCalls = <MethodCall>[];
    final sentActions = <String>[];
    const methodsChannel = MethodChannel('dev.massageflow/godot_methods');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      methodsChannel,
      (call) async {
        sentActions.add(call.arguments as String);
        return true;
      },
    );
    const eventsChannel = 'dev.massageflow/godot_events';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(eventsChannel),
      (_) async => null,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        displayCalls.add(call);
        return null;
      },
    );
    try {
      await tester.pumpWidget(const MassageFlowApp());
      expect(find.text('Massage Flow'), findsOneWidget);
      // The native viewport is already mounted while the menu is visible.
      expect(find.byType(GodotView), findsOneWidget);
      tester.binding.channelBuffers.push(
        eventsChannel,
        const StandardMethodCodec().encodeSuccessEnvelope(<String, Object?>{
          'type': 'godot_ready',
          'payload': '{}',
        }),
        (_) {},
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('open-session')));
      await tester.pumpAndSettle();
      expect(sentActions.last, contains('start_session'));
      tester.binding.channelBuffers.push(
        eventsChannel,
        const StandardMethodCodec().encodeSuccessEnvelope(<String, Object?>{
          'type': 'godot_ready',
          'payload': '{}',
        }),
        (_) {},
      );
      await tester.pump();
      expect(
        sentActions.where((action) => action.contains('start_session')).length,
        1,
      );

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Pause'), findsNothing);
      expect(find.text('back'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(
        tester.getSize(find.byType(GodotView)),
        tester.view.physicalSize / tester.view.devicePixelRatio,
      );
      expect(
        displayCalls
            .where(
              (call) => call.method == 'SystemChrome.setPreferredOrientations',
            )
            .last
            .arguments,
        <String>[
          'DeviceOrientation.landscapeLeft',
          'DeviceOrientation.landscapeRight',
        ],
      );
      expect(
        displayCalls
            .where(
              (call) => call.method == 'SystemChrome.setEnabledSystemUIMode',
            )
            .last
            .arguments,
        'SystemUiMode.immersiveSticky',
      );
      expect(
        find.text('Embedded Godot is available on Android.'),
        findsOneWidget,
      );

      // The only back button lives inside Godot and sends this native event.
      tester.binding.channelBuffers.push(
        eventsChannel,
        const StandardMethodCodec().encodeSuccessEnvelope(<String, Object?>{
          'type': 'back_to_menu',
          'payload': '{}',
        }),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-session')), findsOneWidget);
      expect(find.byType(GodotView), findsOneWidget);
      expect(sentActions.last, contains('stop_session'));
      expect(
        displayCalls
            .where(
              (call) => call.method == 'SystemChrome.setPreferredOrientations',
            )
            .last
            .arguments,
        <String>['DeviceOrientation.portraitUp'],
      );
      expect(
        displayCalls
            .where(
              (call) => call.method == 'SystemChrome.setEnabledSystemUIMode',
            )
            .last
            .arguments,
        'SystemUiMode.edgeToEdge',
      );
      await tester.tap(find.byKey(const Key('open-session')));
      await tester.pumpAndSettle();
      expect(
        sentActions.where((action) => action.contains('start_session')).length,
        2,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sentActions.last, contains('request_exit'));
      // Godot responds to a back request by immediately dismissing the route.
      tester.binding.channelBuffers.push(
        eventsChannel,
        const StandardMethodCodec().encodeSuccessEnvelope(<String, Object?>{
          'type': 'back_to_menu',
          'payload': '{}',
        }),
        (_) {},
      );
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodsChannel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(eventsChannel),
        null,
      );
    }
  });
}
