import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Estilos disponibles para el menú lateral.
///
/// `capitulos` es la propuesta de viñetas con borde de tinta; `webtoon` es la
/// propuesta de hilo vertical continuo. Ambas comparten destinos y paleta.
enum DrawerStyle { capitulos, webtoon }

typedef DrawerStyleLoader = Future<String?> Function();
typedef DrawerStyleSaver = Future<void> Function(String value);

final drawerStyleProvider =
    StateNotifierProvider<DrawerStyleNotifier, DrawerStyle>((ref) {
  const storage = FlutterSecureStorage();
  final notifier = DrawerStyleNotifier(
    loadPreference: () => storage.read(key: DrawerStyleNotifier.storageKey),
    savePreference: (value) => storage.write(
      key: DrawerStyleNotifier.storageKey,
      value: value,
    ),
  );
  unawaited(notifier.restore());
  return notifier;
});

class DrawerStyleNotifier extends StateNotifier<DrawerStyle> {
  DrawerStyleNotifier({
    required DrawerStyleLoader loadPreference,
    required DrawerStyleSaver savePreference,
  })  : _loadPreference = loadPreference,
        _savePreference = savePreference,
        super(DrawerStyle.capitulos);

  static const storageKey = 'app_drawer_style';

  final DrawerStyleLoader _loadPreference;
  final DrawerStyleSaver _savePreference;

  Future<void> restore() async {
    try {
      final preference = await _loadPreference();
      for (final style in DrawerStyle.values) {
        if (preference == style.name) state = style;
      }
    } catch (_) {
      // El estilo de capítulos sigue siendo un valor inicial seguro.
    }
  }

  Future<void> setStyle(DrawerStyle style) async {
    state = style;
    try {
      await _savePreference(style.name);
    } catch (_) {
      // El cambio visual se conserva durante la sesión aunque falle el disco.
    }
  }
}
