import 'package:flutter/material.dart';

const massageTitle = TextStyle(
  fontSize: 20,
  height: 1.2,
  fontWeight: FontWeight.w700,
  color: Color(0xFF111827),
);
const _label = TextStyle(
  fontSize: 14,
  height: 1.2,
  fontWeight: FontWeight.w600,
  color: Color(0xFF374151),
);

class MassageSettingsCard extends StatelessWidget {
  const MassageSettingsCard({
    super.key,
    required this.minutes,
    required this.parts,
    required this.onDurationChanged,
    required this.onEdit,
    required this.onStart,
  });
  final int minutes;
  final List<String> parts;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onEdit, onStart;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD1D5DB)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Your massage', style: massageTitle),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Duration', style: _label),
            Text(
              '$minutes min',
              style: _label.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MassageDuration(value: minutes, max: 60, onChanged: onDurationChanged),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: Text('Selected body parts', style: _label)),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF374151),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: parts
              .map(
                (p) => MassageAreaPill(
                  label: switch (p) {
                    'Upper back' => 'Back',
                    'Lower back' => 'Lower Back',
                    _ => p,
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('open-session'),
          onPressed: parts.isEmpty ? null : onStart,
          child: const Text('Start massage'),
        ),
      ],
    ),
  );
}

class MassageAreaPill extends StatelessWidget {
  const MassageAreaPill({super.key, required this.label, this.onRemove});
  final String label;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: onRemove == null ? 12 : 8,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: onRemove == null
          ? const Color(0xFFEEF2FF)
          : const Color(0xFF2563EB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: onRemove == null ? const Color(0xFF2563EB) : Colors.white,
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x4DFFFFFF),
              ),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ],
      ],
    ),
  );
}

class MassageDuration extends StatelessWidget {
  const MassageDuration({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final int value, max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 24,
        child: Row(
          children: [
            const Text(
              '5 min',
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 5,
                max: max.toDouble(),
                divisions: max - 5,
                padding: EdgeInsets.zero,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$max min',
              style: const TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Selected duration: $value min',
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563EB),
        ),
      ),
    ],
  );
}

/// The Figma thumb is a white disk with a soft 0/2/6 shadow, without a border.
class MassageSliderThumb extends SliderComponentShape {
  const MassageSliderThumb();
  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) => const Size(24, 24);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawCircle(
      center + const Offset(0, 2),
      12,
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    context.canvas.drawCircle(center, 12, Paint()..color = Colors.white);
  }
}
