import 'dart:async';

import 'package:flutter/material.dart';

import 'body_selector.dart';
import 'massage_settings_card.dart';

import '../session/session_screen.dart';
import '../../godot/godot_session_controller.dart';

const _blue = Color(0xFF2E88FF);
const _ink = Color(0xFF111827);
const _areas = [
  'Neck',
  'Shoulders',
  'Upper back',
  'Arms',
  'Lower back',
  'Hips',
  'Thighs',
  'Calves',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selected = {};
  final DraggableScrollableController _sheet = DraggableScrollableController();
  ScrollController? _sheetScroll;
  bool _details = false;
  int _minutes = 25;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _toggle(String area) => setState(() {
    final paired = area.startsWith('Left ') || area.startsWith('Right ');
    final group = paired
        ? [
            'Left ${area.substring(area.indexOf(' ') + 1)}',
            'Right ${area.substring(area.indexOf(' ') + 1)}',
          ]
        : [area];
    if (_selected.contains(area)) {
      _selected.removeAll(group);
    } else {
      _selected.addAll(group);
    }
  });

  void _edit() {
    _sheetScroll?.jumpTo(0);
    if (_sheet.isAttached) _sheet.reset();
    setState(() => _details = false);
  }

  Future<void> _start(int minutes, Set<String> parts) async {
    final session = GodotSessionController.instance;
    session.open(durationMinutes: minutes, bodyParts: parts.toList());
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SessionScreen()),
      );
    } finally {
      session.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeInsets = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: _blue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelTop = (399 - safeInsets.top).clamp(
              220.0,
              constraints.maxHeight * .55,
            );
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: (120 - safeInsets.top).clamp(0.0, 120.0),
                  height: (constraints.maxHeight + safeInsets.top - 120).clamp(
                    0.0,
                    667.0,
                  ),
                  child: BodySelector(selected: _selected, onToggle: _toggle),
                ),
                Positioned(
                  left: 12,
                  right: 20,
                  top: (71 - safeInsets.top).clamp(12.0, 71.0),
                  child: const _WelcomeHeader(),
                ),
                if (!_details)
                  Positioned(
                    bottom: (54 - safeInsets.bottom).clamp(20.0, 54.0),
                    right: 24,
                    child: OutlinedButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => setState(() => _details = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: .15),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        minimumSize: const Size(120, 50),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  key: const ValueKey('massage-panel'),
                  child: IgnorePointer(
                    ignoring: !_details,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeInOutCubic,
                      offset: _details ? Offset.zero : const Offset(0, 1),
                      child: DraggableScrollableSheet(
                        key: const Key('massage-sheet'),
                        controller: _sheet,
                        initialChildSize: 1 - panelTop / constraints.maxHeight,
                        minChildSize: 1 - panelTop / constraints.maxHeight,
                        maxChildSize:
                            (1 -
                                    (168 - safeInsets.top).clamp(
                                          0.0,
                                          panelTop,
                                        ) /
                                        constraints.maxHeight)
                                .clamp(
                                  1 - panelTop / constraints.maxHeight,
                                  1.0,
                                ),
                        builder: (context, scrollController) {
                          _sheetScroll = scrollController;
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            child: Stack(
                              children: [
                                ColoredBox(
                                  color: const Color(0xFFF9FAFB),
                                  child: ListView(
                                    key: const Key('massage-list'),
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(24),
                                    children: [
                                      MassageSettingsCard(
                                        minutes: _minutes,
                                        parts: _selected.toList(),
                                        onDurationChanged: (v) =>
                                            setState(() => _minutes = v),
                                        onEdit: _edit,
                                        onStart: () =>
                                            _start(_minutes, _selected),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'More massages',
                                        style: _title,
                                      ),
                                      const SizedBox(height: 16),
                                      for (final massage in _catalog)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: _MassageCard(
                                            massage: massage,
                                            onStart: _start,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC4C9D0),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _title = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: _ink,
);
Widget _card(Widget child) => Container(
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFD1D5DB)),
    borderRadius: BorderRadius.circular(24),
  ),
  child: child,
);

class _MassageCard extends StatefulWidget {
  const _MassageCard({required this.massage, required this.onStart});
  final _Massage massage;
  final Future<void> Function(int, Set<String>) onStart;
  @override
  State<_MassageCard> createState() => _MassageCardState();
}

class _MassageCardState extends State<_MassageCard> {
  bool _expanded = false;
  late int _minutes = widget.massage.minutes;
  late final Set<String> _parts = widget.massage.parts.toSet();
  @override
  Widget build(BuildContext context) {
    final m = widget.massage;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 160, color: m.color),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: _title),
                      const SizedBox(height: 8),
                      Text(
                        '$_minutes min',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.description,
                        style: const TextStyle(
                          height: 1.4,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Intensity: ${m.intensity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        MassageDuration(
                          value: _minutes,
                          max: 30,
                          onChanged: (v) => setState(() => _minutes = v),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Selected areas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Add body part',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (part) =>
                                  setState(() => _parts.add(part)),
                              itemBuilder: (_) => {..._areas, ...m.parts}
                                  .where((p) => !_parts.contains(p))
                                  .map(
                                    (part) => PopupMenuItem(
                                      value: part,
                                      child: Text(part),
                                    ),
                                  )
                                  .toList(),
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: Icon(Icons.add, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _parts
                              .map(
                                (part) => MassageAreaPill(
                                  label: part,
                                  onRemove: () =>
                                      setState(() => _parts.remove(part)),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _parts.isEmpty
                              ? null
                              : () => widget.onStart(_minutes, _parts),
                          child: const Text('Start massage'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Massage {
  const _Massage(
    this.name,
    this.minutes,
    this.description,
    this.intensity,
    this.color,
    this.parts,
  );
  final String name, description, intensity;
  final int minutes;
  final Color color;
  final List<String> parts;
}

const _catalog = [
  _Massage(
    'Back',
    15,
    'Deep pressure and slow strokes to ease tension across the upper and lower back.',
    'Medium',
    Color(0xFF8B5CF6),
    ['Upper back', 'Lower back', 'Shoulders'],
  ),
  _Massage(
    'Shoulders',
    10,
    'Targeted pressure to release knots and stiffness in the shoulder area.',
    'Firm',
    Color(0xFF3B82F6),
    ['Shoulders'],
  ),
  _Massage(
    'Lower Back',
    15,
    'Gentle warmth and long strokes to soothe the lower spine and hips.',
    'Gentle',
    Color(0xFF10B981),
    ['Lower back', 'Hips'],
  ),
  _Massage(
    'Neck',
    10,
    'Precise pressure to loosen tight muscles and improve range of motion.',
    'Medium',
    Color(0xFFF59E0B),
    ['Neck'],
  ),
  _Massage(
    'Arms',
    12,
    'Long strokes and forearm work to ease strain from daily use.',
    'Light',
    Color(0xFFEF4444),
    ['Arms'],
  ),
  _Massage(
    'Full legs',
    10,
    'Quick refresh for the entire lower body, from hips to toes.',
    'Light',
    Color(0xFF6366F1),
    ['Hips', 'Thighs', 'Calves'],
  ),
  _Massage(
    'Thighs',
    12,
    'Deep pressure to target the front and back of the thigh muscles.',
    'Firm',
    Color(0xFFEC4899),
    ['Thighs'],
  ),
  _Massage(
    'Calves',
    8,
    'Quick release for the lower leg muscles and Achilles tendon.',
    'Medium',
    Color(0xFFF97316),
    ['Calves'],
  ),
  _Massage(
    'Feet',
    10,
    'Reflexology-inspired pressure points for the soles and arches.',
    'Gentle',
    Color(0xFF14B8A6),
    ['Feet'],
  ),
  _Massage(
    'Hands',
    8,
    'Gentle work for the palms, wrists, and fingers.',
    'Light',
    Color(0xFFB84F21),
    ['Hands'],
  ),
];

class _WelcomeHeader extends StatefulWidget {
  const _WelcomeHeader();
  @override
  State<_WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<_WelcomeHeader>
    with SingleTickerProviderStateMixin {
  static const title = 'Welcome back!';
  static const subtitle = 'What are we massaging today?';
  late final AnimationController _typing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3100),
  );
  Timer? _blink;
  bool _cursor = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _typing.value = 1;
    } else {
      _typing.forward();
      _blink = Timer.periodic(const Duration(milliseconds: 550), (_) {
        if (mounted) setState(() => _cursor = !_cursor);
      });
    }
  }

  @override
  void dispose() {
    _blink?.cancel();
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final avatarSize = bounds.maxWidth < 330 ? 62.0 : 72.0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSlide(
            offset: MediaQuery.disableAnimationsOf(context)
                ? Offset.zero
                : Offset(0, _cursor ? 0 : -.035),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutSine,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Transform.flip(
                flipX: true,
                child: Image.asset(
                  'assets/figma/llama_header.png',
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedBuilder(
              animation: _typing,
              builder: (context, _) {
                final count =
                    (((_typing.value * 3100 - 650) / 2450).clamp(0.0, 1.0) *
                            (title.length + subtitle.length))
                        .floor();
                final titleCount = count.clamp(0, title.length);
                final subtitleCount = (count - title.length).clamp(
                  0,
                  subtitle.length,
                );
                return SizedBox(
                  height: avatarSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title.substring(0, titleCount),
                          style: const TextStyle(
                            fontSize: 29,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: subtitle.substring(0, subtitleCount),
                            ),
                            TextSpan(
                              text: _cursor ? '▏' : ' ',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xB3FFFFFF),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
