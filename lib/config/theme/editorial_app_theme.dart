import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_fonts.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class AppRadius {
  static const double lightCard = 14;
  static const double lightControl = 12;
  static const double lightFab = 16;
  static const double darkCard = 18;
  static const double darkControl = 14;
  static const double darkFab = 18;
}

/// Implementación de producción de la propuesta "Magenta editorial".
///
/// La fuente de diseño se conserva en `docs/design-spec.md`. Mantener este
/// tema separado permite probar futuras propuestas sin perder la anterior.
abstract final class EditorialAppTheme {
  static const transitionDuration = Duration(milliseconds: 360);
  static const transitionCurve = Curves.easeInOutCubic;

  static const _lightBackground = Color(0xFFFDF9FC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightOnSurface = Color(0xFF241626);
  static const _lightOnSurfaceVariant = Color(0xFF8A7A88);
  static const _lightOutline = Color(0xFFECE1EA);
  static const _lightPrimary = Color(0xFF9A1E74);

  static const _darkBackground = Color(0xFF131117);
  static const _darkSurface = Color(0xFF1B1820);
  static const _darkOnSurface = Color(0xFFF1EEF5);
  static const _darkOnSurfaceVariant = Color(0xFF9089A0);
  static const _darkOutline = Color(0xFF2C2833);
  static const _darkPrimary = Color(0xFFFF3FA0);

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        background: _lightBackground,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        onSurfaceVariant: _lightOnSurfaceVariant,
        outline: _lightOutline,
        primary: _lightPrimary,
        onPrimary: Colors.white,
        cardRadius: AppRadius.lightCard,
        controlRadius: AppRadius.lightControl,
        fabRadius: AppRadius.lightFab,
        outlinedPrimaryActions: false,
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        background: _darkBackground,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        onSurfaceVariant: _darkOnSurfaceVariant,
        outline: _darkOutline,
        primary: _darkPrimary,
        onPrimary: _darkSurface,
        cardRadius: AppRadius.darkCard,
        controlRadius: AppRadius.darkControl,
        fabRadius: AppRadius.darkFab,
        outlinedPrimaryActions: true,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color primary,
    required Color onPrimary,
    required double cardRadius,
    required double controlRadius,
    required double fabRadius,
    required bool outlinedPrimaryActions,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer:
          primary.withOpacity(brightness == Brightness.dark ? 0.16 : 0.10),
      onPrimaryContainer: primary,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: primary.withOpacity(0.12),
      onSecondaryContainer: primary,
      tertiary: primary,
      onTertiary: onPrimary,
      tertiaryContainer: primary.withOpacity(0.12),
      onTertiaryContainer: primary,
      error: brightness == Brightness.dark
          ? const Color(0xFFFFB4AB)
          : const Color(0xFFBA1A1A),
      onError: brightness == Brightness.dark
          ? const Color(0xFF690005)
          : Colors.white,
      errorContainer: brightness == Brightness.dark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: brightness == Brightness.dark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410002),
      background: background,
      onBackground: onSurface,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline,
      shadow: Colors.black,
      scrim: brightness == Brightness.dark
          ? Colors.black.withOpacity(0.60)
          : onSurface.withOpacity(0.45),
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: primary,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      headlineSmall: AppFonts.displayStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: onSurface,
      ),
      titleLarge: AppFonts.displayStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: onSurface,
      ),
      titleMedium: AppFonts.displayStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleSmall: AppFonts.displayStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      bodyLarge: AppFonts.bodyStyle(
        fontSize: 15,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: AppFonts.bodyStyle(
        fontSize: 14.5,
        height: 1.4,
        color: onSurface,
      ),
      bodySmall: AppFonts.bodyStyle(
        fontSize: 12,
        height: 1.35,
        color: onSurfaceVariant,
      ),
      labelLarge: AppFonts.bodyStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: AppFonts.bodyStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
      ),
    );

    final primaryButtonStyle = ButtonStyle(
      minimumSize: const MaterialStatePropertyAll(Size(44, 48)),
      padding: const MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        titleTextStyle: textTheme.titleLarge,
        shape: Border(bottom: BorderSide(color: outline)),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: surface,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      drawerTheme: DrawerThemeData(
        backgroundColor:
            brightness == Brightness.dark ? const Color(0xFF17151B) : surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: colorScheme.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(cardRadius + 4),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.md,
        iconColor: onSurfaceVariant,
        textColor: onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: primaryButtonStyle),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: outlinedPrimaryActions ? surface : primary,
        foregroundColor: outlinedPrimaryActions ? primary : onPrimary,
        elevation: outlinedPrimaryActions ? 0 : 3,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          color: outlinedPrimaryActions ? primary : onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fabRadius),
          side: outlinedPrimaryActions
              ? BorderSide(color: primary, width: 1.5)
              : BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
    );
  }
}
