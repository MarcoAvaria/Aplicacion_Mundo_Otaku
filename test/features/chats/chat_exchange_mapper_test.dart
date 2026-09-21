import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/mappers/chat_exchange_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final commonJson = <String, dynamic>{
    'id': 'exchange-id',
    'status': 'inProgress',
    'messages': [
      {
        'content': 'Hola',
        'sendBy': 'owner-2',
        'timestamp': '2026-09-20T10:15:00.000Z',
      },
    ],
  };

  test('maps the current explicit relation response', () {
    final exchange = ChatExchangeMapper.jsonToEntity({
      ...commonJson,
      'owner1': {'id': 'owner-1'},
      'owner2': {'id': 'owner-2'},
      'product1': {'id': 'product-1'},
      'product2': {'id': 'product-2'},
      'requester1': {'id': 'product-2'},
    });

    expect(exchange.owner1, 'owner-1');
    expect(exchange.product2, 'product-2');
    expect(exchange.messages.single.content, 'Hola');
  });

  test('keeps compatibility with legacy lazy relation keys', () {
    final exchange = ChatExchangeMapper.jsonToEntity({
      ...commonJson,
      '__owner1__': {'id': 'owner-1'},
      '__owner2__': {'id': 'owner-2'},
      '__product1__': {'id': 'product-1'},
      '__product2__': {'id': 'product-2'},
      '__requester1__': {'id': 'product-2'},
    });

    expect(exchange.owner2, 'owner-2');
    expect(exchange.requester1, 'product-2');
  });

  test('conserva quién envió cada mensaje y cuándo', () {
    final exchange = ChatExchangeMapper.jsonToEntity({
      ...commonJson,
      'owner1': {'id': 'owner-1'},
      'owner2': {'id': 'owner-2'},
      'messages': [
        {
          'content': 'Hola',
          'sendBy': 'owner-2',
          'timestamp': '2026-09-20T10:15:00.000Z',
        },
        {
          'content': '¿Sigue disponible?',
          'sendBy': 'owner-2',
          'timestamp': '2026-09-20T10:16:30.000Z',
        },
      ],
    });

    expect(exchange.messages, hasLength(2));
    expect(exchange.messages.first.sendBy, 'owner-2');
    expect(
      exchange.messages.first.timestamp,
      DateTime.parse('2026-09-20T10:15:00.000Z'),
    );
    expect(exchange.messages.last.content, '¿Sigue disponible?');
  });

  test('tolera mensajes antiguos sin autor ni fecha', () {
    final exchange = ChatExchangeMapper.jsonToEntity({
      ...commonJson,
      'owner1': {'id': 'owner-1'},
      'messages': [
        {'content': 'Mensaje viejo'},
      ],
    });

    final message = exchange.messages.single;
    expect(message.content, 'Mensaje viejo');
    expect(message.sendBy, isEmpty);
    expect(message.timestamp, isNull);
  });

  test('tolera un intercambio sin la clave de mensajes', () {
    final exchange = ChatExchangeMapper.jsonToEntity({
      'id': 'exchange-id',
      'status': 'pending',
      'owner1': {'id': 'owner-1'},
    });

    expect(exchange.messages, isEmpty);
  });
}
