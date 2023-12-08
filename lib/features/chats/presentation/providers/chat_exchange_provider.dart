import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_repository_provider.dart';

final chatExchangeProvider = StateNotifierProvider.autoDispose
    .family<ChatExchangeNotifier, ChatExchangeState, String>(
        (ref, chatExchangeId) {
  final chatExchangesRepository = ref.watch(chatExchangesRepositoryProvider);

  return ChatExchangeNotifier(
    chatExchangesRepository: chatExchangesRepository,
    chatExchangeId: chatExchangeId);
});

class ChatExchangeNotifier extends StateNotifier<ChatExchangeState> {
  final ChatExchangesRepository chatExchangesRepository;

  ChatExchangeNotifier({
    required this.chatExchangesRepository,
    required String chatExchangeId
  }) : super(ChatExchangeState(id: chatExchangeId)) {
    loadChatExchange();
  }

  ChatExchange newEmptyChatExchange() {
    return ChatExchange(
      id: 'new',
      product1: '', 
      product2: '',
      requester1: '',
      messages: [],
    );
  }

  Future<void> loadChatExchange() async {
    try {
      if (state.id == 'new') {
        state = state.copyWith(
          isLoading: false,
          chatExchange: newEmptyChatExchange(),
        );
        return;
      }

      final chatExchange = await chatExchangesRepository.getChatExchangeById(state.id);
      state = state.copyWith(isLoading: false, chatExchange: chatExchange);
    } catch (e) {
      // 404 Producto no encontrado
      print(e);
    }
  }

}

class ChatExchangeState {
  final String id;
  final ChatExchange? chatExchange;
  final bool isLoading;
  final bool isSaving;

  ChatExchangeState({
    required this.id,
    this.chatExchange,
    this.isLoading = true,
    this.isSaving = false,
  });

  ChatExchangeState copyWith({
    String? id,
    ChatExchange? chatExchange,
    bool? isLoading,
    bool? isSaving,
  }) =>
      ChatExchangeState(
        id: id ?? this.id,
        chatExchange: chatExchange ?? this.chatExchange,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
      );
}

