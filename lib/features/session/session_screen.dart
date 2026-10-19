import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../godot/godot_bridge.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  StreamSubscription<GodotEvent>? _eventsSubscription;
  bool _returningToMenu = false;

  @override
  void initState() {
    super.initState();
    _eventsSubscription = GodotBridge.instance.events.listen((event) {
      if (event.type == 'back_to_menu' && mounted && !_returningToMenu) {
        _returningToMenu = true;
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
    unawaited(_enterFullscreen());
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!mounted) await _restoreMenuDisplay();
  }

  Future<void> _restoreMenuDisplay() async {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    unawaited(_eventsSubscription?.cancel());
    unawaited(_restoreMenuDisplay());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _returningToMenu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(GodotBridge.instance.send('request_exit'));
      },
      child: const SizedBox.expand(),
    );
  }
}
