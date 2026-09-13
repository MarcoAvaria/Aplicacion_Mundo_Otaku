import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes', () {
    test('builds parameterized navigation paths in one place', () {
      expect(AppRoutes.product('product 1'), '/product/product%201');
      expect(
        AppRoutes.chat(
          conversationId: 'exchange 1',
          myProductId: 'mine',
          otherProductId: 'other',
        ),
        '/chatscreen/exchange%201/mine/other',
      );
    });
  });

  group('ApiEndpoints', () {
    test('encodes identifiers without changing the endpoint contract', () {
      expect(ApiEndpoints.product('product 1'), '/products/product%201');
      expect(
        ApiEndpoints.chatExchangeStatus('exchange 1'),
        '/chat-exchanges/exchange%201/status',
      );
    });
  });
}
