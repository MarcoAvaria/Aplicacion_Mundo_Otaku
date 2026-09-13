import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/auth_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expone un fallo de intercambios y lo limpia al reintentar', () async {
    final repository = _ChatExchangesRepository();
    final notifier = ChatExchangesNotifier(
      chatExchangesRepository: repository,
      authState: AuthState(),
      loadOnCreate: false,
    );

    repository.failNextRequest = true;
    await notifier.loadAllChatExchanges('user-1');

    expect(notifier.state.isLoading, isFalse);
    expect(
      notifier.state.errorMessage,
      'No fue posible cargar los intercambios.',
    );

    await notifier.loadAllChatExchanges('user-1');

    expect(notifier.state.errorMessage, isEmpty);
    expect(notifier.state.chatExchanges.single.id, 'exchange-1');
    expect(repository.requestedUserIds, ['user-1', 'user-1']);
  });
}

class _ChatExchangesRepository implements ChatExchangesRepository {
  bool failNextRequest = false;
  final requestedUserIds = <String>[];

  @override
  Future<List<ChatExchange>> getAllChatExchanges(String id) async {
    requestedUserIds.add(id);
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('sin conexión');
    }
    return [
      ChatExchange(
        id: 'exchange-1',
        owner1: 'user-1',
        owner2: 'user-2',
        product1: 'product-1',
        product2: 'product-2',
        requester1: 'product-2',
        messages: const [],
        status: 'pending',
      ),
    ];
  }

  @override
  Future<ChatExchange> changeChatExchangeStatus(String id, String status) =>
      throw UnimplementedError();

  @override
  Future<ChatExchange> createUpdateChatExchange(
          Map<String, dynamic> chatExchangeLike) =>
      throw UnimplementedError();

  @override
  Future<ChatExchange> getChatExchangeById(String id) =>
      throw UnimplementedError();

  @override
  Future<List<ChatExchange>> getChatExchangesByPage({
    int limit = 10,
    int offset = 0,
  }) =>
      throw UnimplementedError();
}
