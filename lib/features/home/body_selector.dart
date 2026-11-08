import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BodySelector extends StatelessWidget {
  const BodySelector({
    super.key,
    required this.selected,
    required this.onToggle,
  });
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final scale = math.min(bounds.maxWidth / 380, bounds.maxHeight / 667);
      // Align the original Figma sector canvas to the supplied replacement photo.
      const sx = 380 / 392.7;
      const sy = 518 / 536;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 380 * scale,
          height: 667 * scale,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/figma/body_selector.png',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
              for (final sector in _sectors)
                Positioned(
                  left: (sector.x - .75) * sx * scale,
                  top: ((sector.y - 21 - .75) * sy + 72) * scale,
                  width: (sector.w + 1.5) * sx * scale,
                  height: (sector.h + 1.5) * sy * scale,
                  child: Semantics(
                    label: sector.name,
                    button: true,
                    selected: selected.contains(sector.name),
                    child: Tooltip(
                      message: sector.name,
                      child: GestureDetector(
                        key: ValueKey('sector-${sector.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onToggle(sector.name),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix([
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            selected.contains(sector.name) ? 7 : 1,
                            0,
                          ]),
                          child: Transform.flip(
                            flipX: sector.id.endsWith('_l'),
                            child: SvgPicture.asset(
                              'assets/figma/sector_${sector.id}.svg',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _Sector {
  const _Sector(this.id, this.name, this.x, this.y, this.w, this.h);
  final String id, name;
  final double x, y, w, h;
}

const _sectors = [
  _Sector('shoulder_r', 'Right shoulder', 248.02, 111.17, 29.48, 38.35),
  _Sector('triceps_r', 'Right triceps', 261, 154, 41.5, 42.94),
  _Sector('forearm_r', 'Right forearm', 288, 200, 40, 44),
  _Sector('hip_r', 'Right glute', 200.48, 251.13, 44.02, 65.06),
  _Sector('thigh_r', 'Right thigh', 213.92, 329, 37.20, 58.92),
  _Sector('calf_r', 'Right calf', 228.04, 399.49, 28.43, 84.01),
  _Sector('neck', 'Neck', 181.88, 79.13, 28.94, 19.12),
  _Sector('upper_back', 'Upper back', 147.78, 98.77, 97.14, 84.16),
  _Sector('shoulder_l', 'Left shoulder', 115.20, 111.17, 29.48, 38.35),
  _Sector('triceps_l', 'Left triceps', 90.20, 154, 41.5, 42.94),
  _Sector('forearm_l', 'Left forearm', 64.70, 200, 40, 44),
  _Sector('hip_l', 'Left glute', 148.20, 251.13, 44.02, 65.06),
  _Sector('thigh_l', 'Left thigh', 141.58, 329, 37.20, 58.92),
  _Sector('calf_l', 'Left calf', 136.23, 399.49, 28.43, 84.01),
  _Sector('middle_back', 'Middle back', 155.51, 160.33, 81.67, 47.89),
  _Sector('lower_back', 'Lower back', 183, 201, 28, 27),
];
