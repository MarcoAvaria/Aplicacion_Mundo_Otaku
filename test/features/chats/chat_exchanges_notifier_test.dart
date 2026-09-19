import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/auth_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchange_provider.dart';
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

  test('permite reintentar la carga de una solicitud individual', () async {
    final repository = _ChatExchangesRepository()..failNextExchangeLoad = true;
    final notifier = ChatExchangeNotifier(
      chatExchangesRepository: repository,
      chatExchangeId: 'exchange-1',
      loadOnCreate: false,
    );

    await notifier.loadChatExchange();
    expect(notifier.state.errorMessage, 'No fue posible cargar la solicitud.');
    expect(notifier.state.chatExchange, isNull);

    await notifier.loadChatExchange();
    expect(notifier.state.errorMessage, isEmpty);
    expect(notifier.state.chatExchange?.id, 'exchange-1');
  });

  test('informa cuando no puede cambiar el estado de una solicitud', () async {
    final repository = _ChatExchangesRepository()..failNextStatusUpdate = true;
    final notifier = ChatExchangeNotifier(
      chatExchangesRepository: repository,
      chatExchangeId: 'exchange-1',
      loadOnCreate: false,
    );

    final wasUpdated = await notifier.updateChatExchangeStatus('rejected');

    expect(wasUpdated, isFalse);
    expect(notifier.state.isSaving, isFalse);
    expect(
      notifier.state.errorMessage,
      'No fue posible actualizar la solicitud.',
    );
  });
}

class _ChatExchangesRepository implements ChatExchangesRepository {
  bool failNextRequest = false;
  bool failNextExchangeLoad = false;
  bool failNextStatusUpdate = false;
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
  Future<ChatExchange> changeChatExchangeStatus(
      String id, String status) async {
    if (failNextStatusUpdate) {
      failNextStatusUpdate = false;
      throw Exception('falló la actualización');
    }
    return _exchange()..status = status;
  }

  @override
  Future<ChatExchange> createChatExchange(
          Map<String, dynamic> chatExchangeLike) =>
      throw UnimplementedError();

  @override
  Future<ChatExchange> getChatExchangeById(String id) async {
    if (failNextExchangeLoad) {
      failNextExchangeLoad = false;
      throw Exception('falló la carga');
    }
    return _exchange();
  }

  @override
  Future<List<ChatExchange>> getChatExchangesByPage({
    int limit = 10,
    int offset = 0,
  }) =>
      throw UnimplementedError();

  ChatExchange _exchange() => ChatExchange(
        id: 'exchange-1',
        owner1: 'user-1',
        owner2: 'user-2',
        product1: 'product-1',
        product2: 'product-2',
        requester1: 'product-2',
        messages: const [],
        status: 'pending',
      );
}
