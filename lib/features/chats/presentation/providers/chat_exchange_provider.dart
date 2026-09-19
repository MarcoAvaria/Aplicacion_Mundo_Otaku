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
      {required this.chatExchangesRepository,
      required String chatExchangeId,
      bool loadOnCreate = true})
      : super(ChatExchangeState(id: chatExchangeId)) {
    if (loadOnCreate) loadChatExchange();
  }

  ChatExchange newEmptyChatExchange() {
    return ChatExchange(
      id: 'new',
      product1: '',
      product2: '',
      owner1: '',
      owner2: '',
      requester1: '',
      messages: [],
      status: 'pending',
    );
  }

  Future<void> loadChatExchange() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
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
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No fue posible cargar la solicitud.',
      );
    }
  }

  Future<bool> updateChatExchangeStatus(String status) async {
    if (!isValidStatus(status)) return false;

    try {
      state = state.copyWith(isSaving: true, errorMessage: '');

      final updatedChatExchange = await chatExchangesRepository
          .changeChatExchangeStatus(state.id, status);

      state = state.copyWith(
        isSaving: false,
        chatExchange: updatedChatExchange,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No fue posible actualizar la solicitud.',
      );
      return false;
    }
  }

  bool isValidStatus(String status) {
    final validStatusList = [
      'pending',
      'abort',
      'rejected',
      'inProgress',
      'done',
      'cancelled'
    ];
    return validStatusList.contains(status);
  }
}

class ChatExchangeState {
  final String id;
  final ChatExchange? chatExchange;
  final bool isLoading;
  final bool isSaving;
  final String errorMessage;

  ChatExchangeState({
    required this.id,
    this.chatExchange,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage = '',
  });

  ChatExchangeState copyWith({
    String? id,
    ChatExchange? chatExchange,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) =>
      ChatExchangeState(
        id: id ?? this.id,
        chatExchange: chatExchange ?? this.chatExchange,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
