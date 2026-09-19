import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaura el modo oscuro guardado', () async {
    final notifier = AppThemeModeNotifier(
      loadPreference: () async => 'dark',
      savePreference: (_) async {},
    );

    await notifier.restore();

    expect(notifier.state, ThemeMode.dark);
  });

  test('cambia a modo claro y guarda la preferencia', () async {
    String? savedPreference;
    final notifier = AppThemeModeNotifier(
      loadPreference: () async => null,
      savePreference: (value) async => savedPreference = value,
    );

    await notifier.setDarkMode(false);

    expect(notifier.state, ThemeMode.light);
    expect(savedPreference, 'light');
  });
}
