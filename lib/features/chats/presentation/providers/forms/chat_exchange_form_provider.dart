import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatExchangeFormProvider = StateNotifierProvider.autoDispose
    .family<ChatExchangeFormNotifier, ChatExchangeFormState, ChatExchange>(
        (ref, chatExchange) {
  final createUpdateCallback =
      ref.watch(chatExchangesProvider.notifier).createOrUpdateChatExchange;
  return ChatExchangeFormNotifier(
    chatExchange: chatExchange,
    onSubmitCallback: createUpdateCallback,
  );
});

class ChatExchangeFormNotifier extends StateNotifier<ChatExchangeFormState> {
  final Future<bool> Function(Map<String, dynamic> chatExchangeLike)?
      onSubmitCallback;
  ChatExchangeFormNotifier({
    this.onSubmitCallback,
    required ChatExchange chatExchange,
  }) : super(ChatExchangeFormState(
          id: chatExchange.id,
          product1: chatExchange.product1,
          product2: chatExchange.product2,
          requester1: chatExchange.requester1,
          messages: chatExchange.messages,
        ));

  Future<bool> onFormSubmit() async {
    if (onSubmitCallback == null) return false;

    final chatExchangeLike = {
      'id': (state.id == 'new') ? null : state.id,
      'product1': state.product1,
      'product2': state.product2,
      'requester1': state.requester1,
      'messages': state.messages,
    };

    try {
      final result = await onSubmitCallback!(chatExchangeLike);
      print(result); // Agrega esto para imprimir la respuesta.
      return result;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<String?> getFormStateId() async {
    return state.id;
  }
}

class ChatExchangeFormState {
  final String? id;
  final String product1;
  final String product2;
  final String requester1;
  final List<String> messages;

  ChatExchangeFormState({
    this.id,
    this.product1 = '',
    this.product2 = '',
    this.requester1 = '',
    this.messages = const [],
  });

  ChatExchangeFormState copyWith({
    String? id,
    String? product1,
    String? product2,
    String? requester1,
    List<String>? messages,
  }) =>
      ChatExchangeFormState(
        id: id ?? this.id,
        product1: product1 ?? this.product1,
        product2: product2 ?? this.product2,
        requester1: requester1 ?? this.requester1,
        messages: messages ?? this.messages,
      );
}
