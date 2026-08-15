import 'package:flutter/material.dart';

class InjaziTheme {
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF115E59);
  static const bg = Color(0xFFF7F9FC);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF64748B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
