import 'package:aplicacion_mundo_otaku/features/chats/infrastructure/mappers/chat_exchange_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final commonJson = <String, dynamic>{
    'id': 'exchange-id',
    'status': 'inProgress',
    'messages': [
      {'content': 'Hola'},
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
    expect(exchange.messages, ['Hola']);
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
}
