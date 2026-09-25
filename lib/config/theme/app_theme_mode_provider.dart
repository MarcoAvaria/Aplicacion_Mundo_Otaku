import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef ThemeModeLoader = Future<String?> Function();
typedef ThemeModeSaver = Future<void> Function(String value);

final appThemeModeProvider =
    StateNotifierProvider<AppThemeModeNotifier, ThemeMode>((ref) {
  const storage = FlutterSecureStorage();
  final notifier = AppThemeModeNotifier(
    loadPreference: () => storage.read(key: AppThemeModeNotifier.storageKey),
    savePreference: (value) => storage.write(
      key: AppThemeModeNotifier.storageKey,
      value: value,
    ),
  );
  unawaited(notifier.restore());
  return notifier;
});

class AppThemeModeNotifier extends StateNotifier<ThemeMode> {
  AppThemeModeNotifier({
    required ThemeModeLoader loadPreference,
    required ThemeModeSaver savePreference,
  })  : _loadPreference = loadPreference,
        _savePreference = savePreference,
        super(ThemeMode.system);

  static const storageKey = 'app_theme_mode';

  final ThemeModeLoader _loadPreference;
  final ThemeModeSaver _savePreference;

  Future<void> restore() async {
    try {
      final preference = await _loadPreference();
      if (preference == ThemeMode.light.name) state = ThemeMode.light;
      if (preference == ThemeMode.dark.name) state = ThemeMode.dark;
    } catch (_) {
      // El tema del sistema sigue siendo un valor inicial seguro.
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    try {
      await _savePreference(mode.name);
    } catch (_) {
      // El cambio visual se conserva durante la sesión aunque falle el disco.
    }
  }
}
