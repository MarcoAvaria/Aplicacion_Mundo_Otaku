import 'package:flutter/material.dart';

abstract final class MundoOtakuColors {
  static const night = Color(0xFF11152F);
  static const nightSoft = Color(0xFF1B2043);
  static const coral = Color(0xFFFF6F61);
  static const coralDark = Color(0xFFD94D45);
  static const mint = Color(0xFF70E1C1);
  static const cream = Color(0xFFFFFBF5);
  static const ink = Color(0xFF191B2B);
  static const muted = Color(0xFF696B7B);
  static const outline = Color(0xFFE2DFE6);
}

class AppTheme {
  final int selectedColor;

  AppTheme({this.selectedColor = 0});

  ThemeData getTheme() {
    const colorScheme = ColorScheme.light(
      primary: MundoOtakuColors.coral,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE2DE),
      onPrimaryContainer: MundoOtakuColors.ink,
      secondary: MundoOtakuColors.mint,
      onSecondary: MundoOtakuColors.night,
      surface: MundoOtakuColors.cream,
      onSurface: MundoOtakuColors.ink,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: MundoOtakuColors.outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MundoOtakuColors.cream,
      fontFamily: 'Arial',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: const TextStyle(
          color: MundoOtakuColors.ink,
          fontSize: 40,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: const TextStyle(
          color: MundoOtakuColors.ink,
          fontSize: 30,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: const TextStyle(
          color: MundoOtakuColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: MundoOtakuColors.ink,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: MundoOtakuColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MundoOtakuColors.coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MundoOtakuColors.coral.withOpacity(.45),
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MundoOtakuColors.coralDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: MundoOtakuColors.night,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
