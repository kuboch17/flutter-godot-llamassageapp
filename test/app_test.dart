import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massage_flow/app.dart';

void main() {
  testWidgets('opens the interactive session from the Flutter home screen', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(const MassageFlowApp());
      expect(find.text('Massage Flow'), findsOneWidget);

      await tester.tap(find.byKey(const Key('open-session')));
      await tester.pumpAndSettle();

      expect(find.text('Neck & shoulders'), findsWidgets);
      expect(
        find.text('Embedded Godot is available on Android.'),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
