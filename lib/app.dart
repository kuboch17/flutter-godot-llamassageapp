import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'godot/godot_session_controller.dart';
import 'godot/godot_view.dart';

class MassageFlowApp extends StatelessWidget {
  const MassageFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF49645D);

    return MaterialApp(
      title: 'Massage Flow',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _PreloadedGodotHost(child: child!),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F5EF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class _PreloadedGodotHost extends StatefulWidget {
  const _PreloadedGodotHost({required this.child});
  final Widget child;

  @override
  State<_PreloadedGodotHost> createState() => _PreloadedGodotHostState();
}

class _PreloadedGodotHostState extends State<_PreloadedGodotHost> {
  @override
  void initState() {
    super.initState();
    GodotSessionController.instance.preload();
  }

  @override
  Widget build(BuildContext context) {
    final session = GodotSessionController.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const GodotView(key: ValueKey('preloaded-godot')),
          IgnorePointer(
            ignoring: session.active,
            child: Opacity(
              opacity: session.active ? 0 : 1,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
