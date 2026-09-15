import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';

class MassageFlowApp extends StatelessWidget {
  const MassageFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF49645D);

    return MaterialApp(
      title: 'Massage Flow',
      debugShowCheckedModeBanner: false,
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
