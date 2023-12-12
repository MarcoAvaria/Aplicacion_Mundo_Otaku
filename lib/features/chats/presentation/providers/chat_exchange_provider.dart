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

  ChatExchangeNotifier(
      {required this.chatExchangesRepository, required String chatExchangeId})
      : super(ChatExchangeState(id: chatExchangeId)) {
    loadChatExchange();
  }

  ChatExchange newEmptyChatExchange() {
    return ChatExchange(
      id: 'new',
      product1: '',
      product2: '',
      requester1: '',
      messages: [],
      status: 'pending',
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

      final chatExchange =
          await chatExchangesRepository.getChatExchangeById(state.id);
      state = state.copyWith(isLoading: false, chatExchange: chatExchange);
    } catch (e) {
      // 404 Producto no encontrado
      //print(e);
      throw Exception(e);
    }
  }

  Future<void> updateChatExchangeStatus(String status) async {
    if (isValidStatus(status)) {
      try {
        state = state.copyWith(isSaving: true);

        final updatedChatExchange = await chatExchangesRepository
            .changeChatExchangeStatus(state.id, status);

        state =
            state.copyWith(isSaving: false, chatExchange: updatedChatExchange);
      } catch (e) {
        state = state.copyWith(isSaving: false);
        //print('ERROR EN updateChatExchangeStatus EN ChatExchangeNotifier:');
        //print(e);
        throw Exception(e);
        // Manejar el error según tus necesidades
      }
    } else {
      //print('ERROR: Estado no válido');
      throw Exception();
    }
  }

  bool isValidStatus(String status) {
  // Agrega lógica para verificar si el estado es válido
  // Por ejemplo, puedes tener una lista de estados válidos y verificar si el estado está en esa lista.
  final validStatusList = ['pending','abort', 'rejected', 'inProgress', 'done', 'cancelled'];
  return validStatusList.contains(status);
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
