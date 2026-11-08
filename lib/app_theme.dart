import 'package:flutter/material.dart';

import 'features/home/massage_settings_card.dart';

ThemeData buildMassageTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB),
    brightness: Brightness.light,
    surface: const Color(0xFFF9FAFB),
  ),
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  useMaterial3: true,
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      color: Color(0xFF374151),
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: Color(0xFF2E88FF),
    inactiveTrackColor: Color(0xFFD1D5DB),
    thumbColor: Colors.white,
    trackHeight: 10,
    thumbShape: MassageSliderThumb(),
    tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 0),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(51),
      padding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
);
