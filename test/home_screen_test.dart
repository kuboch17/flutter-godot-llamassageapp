import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massage_flow/features/home/home_screen.dart';
import 'package:massage_flow/app_theme.dart';

void main() {
  testWidgets(
    'body selection survives editing and catalog expands independently',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final loader = FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
        await loader.load();
        final iconFont = File(
          '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        if (iconFont.existsSync()) {
          final icons = FontLoader('MaterialIcons')
            ..addFont(
              Future.value(ByteData.sublistView(await iconFont.readAsBytes())),
            );
          await icons.load();
        }
      });
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildMassageTheme(),
          home: RepaintBoundary(key: capture, child: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> screenshot(String name) async {
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('outputs/ui').create(recursive: true);
          await File('outputs/ui/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/figma/body_selector.png'),
          capture.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => precacheImage(const AssetImage('assets/figma/llama_header.png'), capture.currentContext!));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await screenshot('body-selector');
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Next'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('sector-neck')));
      await tester.tap(find.byKey(const ValueKey('sector-shoulder_r')));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Selected duration: 25 min'), findsOneWidget);
      await screenshot('your-massage');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sector-neck')));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      final chips = find.descendant(
        of: find.byType(Wrap).first,
        matching: find.byType(Text),
      );
      expect(chips.evaluate().map((e) => (e.widget as Text).data), [
        'Left shoulder',
        'Right shoulder',
      ]);
      await tester.drag(find.byType(ListView), const Offset(0, -420));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Back'));
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(find.text('Selected areas'), findsOneWidget);
      await screenshot('expanded-massage');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('sheet rises to the header before its list scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: buildMassageTheme(), home: const HomeScreen()),
    );
    await tester.tap(find.byKey(const ValueKey('sector-neck')));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final sheet = tester.widget<DraggableScrollableSheet>(
      find.byKey(const Key('massage-sheet')),
    );
    final controller = sheet.controller!;
    final list = tester
        .widget<ListView>(find.byKey(const Key('massage-list')))
        .controller!;
    final initial = controller.size;
    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(const Key('massage-list'))) +
          const Offset(20, 12),
    );
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(controller.size, greaterThan(initial));
    expect(list.offset, 0);
    await gesture.moveBy(const Offset(0, -260));
    await tester.pump();
    expect(controller.size, closeTo(sheet.maxChildSize, .001));
    expect(list.offset, 0);
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(list.offset, greaterThan(0));
    expect(
      tester.getTopLeft(find.byKey(const Key('massage-list'))).dy,
      closeTo(168, 1),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(initial, .001));
    expect(list.offset, 0);
  });
}


