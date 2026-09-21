import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange_message.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_read_marks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const me = 'user-1';
const other = 'user-2';

ChatExchange _exchange({
  String id = 'exchange-1',
  List<ChatExchangeMessage> messages = const [],
}) {
  return ChatExchange(
    id: id,
    owner1: me,
    owner2: other,
    product1: 'product-1',
    product2: 'product-2',
    requester1: 'product-2',
    status: 'inProgress',
    messages: messages,
  );
}

ChatExchangeMessage _message(String sendBy, String isoTimestamp) {
  return ChatExchangeMessage(
    content: 'texto',
    sendBy: sendBy,
    timestamp: DateTime.parse(isoTimestamp),
  );
}

ChatReadMarksNotifier _notifier({
  String? stored,
  void Function(String value)? onSave,
}) {
  return ChatReadMarksNotifier(
    loadMarks: () async => stored,
    saveMarks: (value) async => onSave?.call(value),
  );
}

void main() {
  test('sin marca previa cuenta todos los mensajes de la otra persona', () {
    final notifier = _notifier();
    final exchange = _exchange(messages: [
      _message(other, '2026-09-20T10:00:00.000Z'),
      _message(me, '2026-09-20T10:01:00.000Z'),
      _message(other, '2026-09-20T10:02:00.000Z'),
    ]);

    expect(notifier.unreadCountFor(exchange: exchange, currentUserId: me), 2);
  });

  test('no cuenta los mensajes propios', () {
    final notifier = _notifier();
    final exchange = _exchange(messages: [
      _message(me, '2026-09-20T10:00:00.000Z'),
      _message(me, '2026-09-20T10:01:00.000Z'),
    ]);

    expect(notifier.unreadCountFor(exchange: exchange, currentUserId: me), 0);
  });

  test('marcar como leído deja el contador en cero', () async {
    final notifier = _notifier();
    final exchange = _exchange(messages: [
      _message(other, '2026-09-20T10:00:00.000Z'),
      _message(other, '2026-09-20T10:02:00.000Z'),
    ]);

    await notifier.markExchangeAsRead(exchange, currentUserId: me);

    expect(notifier.unreadCountFor(exchange: exchange, currentUserId: me), 0);
  });

  test('cuenta solo los mensajes posteriores a la marca', () async {
    final notifier = _notifier();
    final leido = _exchange(messages: [
      _message(other, '2026-09-20T10:00:00.000Z'),
    ]);

    await notifier.markExchangeAsRead(leido, currentUserId: me);

    final conRespuesta = _exchange(messages: [
      _message(other, '2026-09-20T10:00:00.000Z'),
      _message(other, '2026-09-20T10:05:00.000Z'),
      _message(other, '2026-09-20T10:06:00.000Z'),
    ]);

    expect(
      notifier.unreadCountFor(exchange: conRespuesta, currentUserId: me),
      2,
    );
  });

  test('ignora mensajes antiguos sin fecha cuando ya hay una marca', () async {
    final notifier = _notifier();
    await notifier.markReadAt(
      userId: me,
      exchangeId: 'exchange-1',
      timestamp: DateTime.parse('2026-09-20T10:00:00.000Z'),
    );

    final exchange = _exchange(messages: [
      const ChatExchangeMessage(
        content: 'sin fecha',
        sendBy: other,
        timestamp: null,
      ),
    ]);

    expect(notifier.unreadCountFor(exchange: exchange, currentUserId: me), 0);
  });

  test('la marca nunca retrocede', () async {
    final notifier = _notifier();
    await notifier.markReadAt(
      userId: me,
      exchangeId: 'exchange-1',
      timestamp: DateTime.parse('2026-09-20T10:05:00.000Z'),
    );
    await notifier.markReadAt(
      userId: me,
      exchangeId: 'exchange-1',
      timestamp: DateTime.parse('2026-09-20T10:01:00.000Z'),
    );

    final exchange = _exchange(messages: [
      _message(other, '2026-09-20T10:03:00.000Z'),
    ]);

    expect(notifier.unreadCountFor(exchange: exchange, currentUserId: me), 0);
  });

  test('cada intercambio lleva su propia marca', () async {
    final notifier = _notifier();
    await notifier.markReadAt(
      userId: me,
      exchangeId: 'exchange-1',
      timestamp: DateTime.parse('2026-09-20T10:00:00.000Z'),
    );

    final otro = _exchange(id: 'exchange-2', messages: [
      _message(other, '2026-09-19T08:00:00.000Z'),
    ]);

    expect(notifier.unreadCountFor(exchange: otro, currentUserId: me), 1);
  });

  test('las marcas de una cuenta no afectan a la otra en el mismo dispositivo',
      () async {
    final notifier = _notifier();
    final paraMi = _exchange(messages: [
      _message(other, '2026-09-20T10:00:00.000Z'),
    ]);

    // Usuario Demo 1 abre la conversación en este teléfono.
    await notifier.markExchangeAsRead(paraMi, currentUserId: me);
    expect(notifier.unreadCountFor(exchange: paraMi, currentUserId: me), 0);

    // Usuario Demo 2 entra después en el mismo teléfono. El mismo intercambio,
    // visto desde el otro lado, sigue teniendo un mensaje sin leer.
    final paraElOtro = _exchange(messages: [
      _message(me, '2026-09-20T10:00:00.000Z'),
    ]);
    expect(
      notifier.unreadCountFor(exchange: paraElOtro, currentUserId: other),
      1,
    );
  });

  test('guarda y restaura las marcas en disco', () async {
    String? guardado;
    final notifier = _notifier(onSave: (value) => guardado = value);

    await notifier.markReadAt(
      userId: me,
      exchangeId: 'exchange-1',
      timestamp: DateTime.parse('2026-09-20T10:00:00.000Z'),
    );
    expect(guardado, isNotNull);

    final restaurado = _notifier(stored: guardado);
    await restaurado.restore();

    final exchange = _exchange(messages: [
      _message(other, '2026-09-20T09:00:00.000Z'),
      _message(other, '2026-09-20T11:00:00.000Z'),
    ]);

    expect(restaurado.unreadCountFor(exchange: exchange, currentUserId: me), 1);
  });

  test('un contenido guardado ilegible no rompe la restauración', () async {
    final notifier = _notifier(stored: 'esto no es json');

    await notifier.restore();

    expect(notifier.state, isEmpty);
  });

  test('olvida las marcas al cerrar sesión', () async {
    String? guardado;
    final notifier = _notifier(onSave: (value) => guardado = value);
    await notifier.markReadAt(
      userId: me,
      exchangeId: 'exchange-1',
      timestamp: DateTime.parse('2026-09-20T10:00:00.000Z'),
    );

    await notifier.clear();

    expect(notifier.state, isEmpty);
    expect(guardado, '{}');
  });
}
