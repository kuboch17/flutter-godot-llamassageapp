import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../godot/godot_bridge.dart';
import '../../godot/godot_view.dart';

enum _SessionState { starting, ready, paused, unavailable, unsupported }

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final GodotBridge _bridge = GodotBridge.instance;
  StreamSubscription<GodotEvent>? _eventsSubscription;
  _SessionState _sessionState = _SessionState.starting;
  String _instruction = 'Preparing the interactive guide…';
  int _touchCount = 0;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.android) {
      _sessionState = _SessionState.unsupported;
      return;
    }
    _eventsSubscription = _bridge.events.listen(
      _onGodotEvent,
      onError: (_) {
        if (mounted) {
          setState(() => _sessionState = _SessionState.unavailable);
        }
      },
    );
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onViewCreated(int _) async {
    try {
      if (await _bridge.isEngineReady()) {
        await _configureSession();
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _sessionState = _SessionState.unavailable);
      }
    }
  }

  Future<void> _configureSession() async {
    final accepted = await _bridge.send('configure', const <String, Object?>{
      'technique': 'Slow circular pressure',
      'durationSeconds': 300,
    });
    if (mounted && accepted) {
      setState(() {
        _sessionState = _SessionState.ready;
        _instruction = 'Follow the pulse and keep the pressure gentle.';
      });
    }
  }

  void _onGodotEvent(GodotEvent event) {
    if (!mounted) {
      return;
    }

    switch (event.type) {
      case 'engine_ready':
      case 'godot_ready':
        _configureSession();
        break;
      case 'interaction':
        setState(() {
          _touchCount =
              (event.payload['count'] as num?)?.toInt() ?? _touchCount;
          _instruction = 'Great — continue with slow, even circles.';
        });
        break;
      case 'session_complete':
        setState(() => _instruction = 'Session complete. Take a slow breath.');
        break;
    }
  }

  Future<void> _togglePause() async {
    final shouldPause = _sessionState != _SessionState.paused;
    if (await _bridge.send(shouldPause ? 'pause' : 'resume') && mounted) {
      setState(() {
        _sessionState = shouldPause
            ? _SessionState.paused
            : _SessionState.ready;
      });
    }
  }

  Future<void> _reset() async {
    if (await _bridge.send('reset') && mounted) {
      setState(() {
        _touchCount = 0;
        _instruction = 'Follow the pulse and keep the pressure gentle.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready =
        _sessionState == _SessionState.ready ||
        _sessionState == _SessionState.paused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neck & shoulders'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      GodotView(onCreated: _onViewCreated),
                      if (_sessionState == _SessionState.starting)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_sessionState == _SessionState.unavailable)
                        const ColoredBox(
                          color: Color(0xDD17201E),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Text(
                                'Godot could not start. Check the Android build and project assets.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _instruction,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Guided touches: $_touchCount'),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: ready ? _togglePause : null,
                      icon: Icon(
                        _sessionState == _SessionState.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      label: Text(
                        _sessionState == _SessionState.paused
                            ? 'Resume'
                            : 'Pause',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Reset session',
                    onPressed: ready ? _reset : null,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
