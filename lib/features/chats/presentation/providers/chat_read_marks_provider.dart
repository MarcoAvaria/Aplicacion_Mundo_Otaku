import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

typedef ReadMarksLoader = Future<String?> Function();
typedef ReadMarksSaver = Future<void> Function(String value);

/// Hasta qué momento leyó cada cuenta cada intercambio, en este dispositivo.
///
/// La API no lleva registro de lectura por persona, así que el contador de
/// mensajes nuevos se calcula en el cliente: se recuerda la fecha del último
/// mensaje visto en cada conversación y se cuentan los posteriores que escribió
/// la otra persona. Como es local, los contadores parten de cero al reinstalar
/// la aplicación o al entrar desde otro dispositivo.
///
/// Sigue el mismo patrón inyectable de `AppThemeModeNotifier`: el almacenamiento
/// entra por parámetro para poder probar la lógica sin el plugin.
final chatReadMarksProvider =
    StateNotifierProvider<ChatReadMarksNotifier, Map<String, DateTime>>((ref) {
  const storage = FlutterSecureStorage();
  final notifier = ChatReadMarksNotifier(
    loadMarks: () => storage.read(key: ChatReadMarksNotifier.storageKey),
    saveMarks: (value) => storage.write(
      key: ChatReadMarksNotifier.storageKey,
      value: value,
    ),
  );
  unawaited(notifier.restore());
  return notifier;
});

class ChatReadMarksNotifier extends StateNotifier<Map<String, DateTime>> {
  ChatReadMarksNotifier({
    required ReadMarksLoader loadMarks,
    required ReadMarksSaver saveMarks,
  })  : _loadMarks = loadMarks,
        _saveMarks = saveMarks,
        super(const {});

  static const storageKey = 'chat_read_marks';

  static String _keyFor(String userId, String exchangeId) =>
      '$userId|$exchangeId';

  final ReadMarksLoader _loadMarks;
  final ReadMarksSaver _saveMarks;

  Future<void> restore() async {
    try {
      final stored = await _loadMarks();
      if (stored == null || stored.isEmpty) return;

      final decoded = jsonDecode(stored);
      if (decoded is! Map) return;

      final marks = <String, DateTime>{};
      decoded.forEach((key, value) {
        final timestamp = DateTime.tryParse(value?.toString() ?? '');
        if (timestamp != null) marks[key.toString()] = timestamp;
      });
      state = marks;
    } catch (_) {
      // Un contenido ilegible solo significa empezar sin marcas: se verán
      // todos los mensajes como nuevos, que es el peor caso aceptable.
    }
  }

  /// Cuántos mensajes de la otra persona llegaron después de la última lectura.
  int unreadCountFor({
    required ChatExchange exchange,
    required String currentUserId,
  }) {
    final mark = state[_keyFor(currentUserId, exchange.id)];

    return exchange.messages.where((message) {
      if (message.sendBy == currentUserId) return false;
      if (mark == null) return true;

      // Un mensaje sin fecha es de antes de que el servidor la incluyera, así
      // que es anterior a cualquier marca, que solo existe desde esta versión.
      final timestamp = message.timestamp;
      if (timestamp == null) return false;

      return timestamp.isAfter(mark);
    }).length;
  }

  /// Deja el intercambio al día hasta su mensaje más reciente.
  Future<void> markExchangeAsRead(
    ChatExchange exchange, {
    required String currentUserId,
  }) {
    DateTime? latest;
    for (final message in exchange.messages) {
      final timestamp = message.timestamp;
      if (timestamp == null) continue;
      if (latest == null || timestamp.isAfter(latest)) latest = timestamp;
    }
    return markReadAt(
      userId: currentUserId,
      exchangeId: exchange.id,
      timestamp: latest,
    );
  }

  /// Mueve la marca de un intercambio para una cuenta, nunca hacia atrás.
  ///
  /// Se usa la fecha del propio mensaje y no la hora del dispositivo para que
  /// un reloj desajustado no deje mensajes marcados como nuevos para siempre.
  Future<void> markReadAt({
    required String userId,
    required String exchangeId,
    DateTime? timestamp,
  }) async {
    if (userId.isEmpty || exchangeId.isEmpty) return;

    final key = _keyFor(userId, exchangeId);
    final mark = timestamp ?? DateTime.now();
    final current = state[key];
    if (current != null && !mark.isAfter(current)) return;

    state = {...state, key: mark};
    await _persist();
  }

  /// Olvida todas las marcas: la sesión que viene empieza limpia.
  Future<void> clear() async {
    state = const {};
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _saveMarks(jsonEncode(
        state.map((id, mark) => MapEntry(id, mark.toIso8601String())),
      ));
    } catch (_) {
      // El contador sigue correcto durante la sesión aunque falle el disco.
    }
  }
}
