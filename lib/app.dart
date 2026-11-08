import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

import 'app_theme.dart';

import 'features/home/home_screen.dart';
import 'godot/godot_session_controller.dart';
import 'godot/godot_view.dart';

class MassageFlowApp extends StatelessWidget {
  const MassageFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Massage Flow',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        child: _PreloadedGodotHost(child: child!),
      ),
      theme: buildMassageTheme(),
      home: const _LaunchScreen(),
    );
  }
}

class _LaunchScreen extends StatefulWidget {
  const _LaunchScreen();

  @override
  State<_LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<_LaunchScreen> {
  Timer? _timer;
  bool _minimumElapsed = false;
  bool _leaving = false;
  bool _assetsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsReady) return;
    Future.wait([
      precacheImage(
        const AssetImage('assets/figma/body_selector.png'),
        context,
      ),
      precacheImage(const AssetImage('assets/figma/llama_header.png'), context),
    ]).then((_) {
      if (!mounted) return;
      _assetsReady = true;
      _showHomeWhenReady();
    });
  }

  void _showHomeWhenReady() {
    final needsGodot =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!mounted ||
        _leaving ||
        !_minimumElapsed ||
        !_assetsReady ||
        (needsGodot && !GodotSessionController.instance.ready)) {
      return;
    }
    _leaving = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    GodotSessionController.instance.addListener(_showHomeWhenReady);
    _timer = Timer(const Duration(milliseconds: 1400), () {
      _minimumElapsed = true;
      _showHomeWhenReady();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    GodotSessionController.instance.removeListener(_showHomeWhenReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _leaving
      ? const HomeScreen()
      : const Scaffold(
          backgroundColor: Color(0xFF2E88FF),
          body: SafeArea(
            child: Center(
              child: Text(
                'llamassage',
                semanticsLabel: 'Llamassage',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
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
