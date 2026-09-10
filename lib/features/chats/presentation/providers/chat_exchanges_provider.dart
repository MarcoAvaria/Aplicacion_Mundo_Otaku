import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/auth_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_repository_provider.dart';

final chatExchangesProvider =
    StateNotifierProvider<ChatExchangesNotifier, ChatExchangesState>((ref) {
  //AutoDisposeStateNotifierProvider<ChatExchangesNotifier, ChatExchangesState>((ref) {
  final chatExchangesRepository = ref.watch(chatExchangesRepositoryProvider);
  final authState = ref.watch(authProvider);

  return ChatExchangesNotifier(
      chatExchangesRepository: chatExchangesRepository, authState: authState);
});

class ChatExchangesNotifier extends StateNotifier<ChatExchangesState> {
  final ChatExchangesRepository chatExchangesRepository;
  final AuthState authState;
  ChatExchangesNotifier(
      {required this.chatExchangesRepository, required this.authState})
      : super(ChatExchangesState()) {
    // loadNextPage();
    loadAllChatExchanges(authState.user!.id);
  }

  ChatExchange newEmptyProduct() {
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

  Future<bool> createOrUpdateChatExchange(
      Map<String, dynamic> chatExchangeLike) async {
    try {
      final chatExchange = await chatExchangesRepository
          .createUpdateChatExchange(chatExchangeLike);
      //print('chatExchange after API call: $chatExchange');
      final isChatExchangeInList =
          state.chatExchanges.any((element) => element.id == chatExchange.id);

      if (!isChatExchangeInList) {
        state = state
            .copyWith(chatExchanges: [...state.chatExchanges, chatExchange]);
        return true;
      }
      state = state.copyWith(
          chatExchanges: state.chatExchanges
              .map(
                (element) =>
                    (element.id == chatExchange.id) ? chatExchange : element,
              )
              .toList());
      //print(state); // Agrega esta línea para verificar el estado después de la operación.
      return true;
    } catch (e) {
      //print('Error al crear o actualizar el ChatExchange:');
      //print(e);
      return false;
    }
  }

  Future loadNextPage() async {
    if (state.isLoading || state.isLastPage) return;
    state = state.copyWith(isLoading: true);
    final chatExchanges = await chatExchangesRepository.getChatExchangesByPage(
        limit: state.limit, offset: state.offset);
    if (chatExchanges.isEmpty) {
      state = state.copyWith(isLoading: false, isLastPage: true);
      return;
    }
    state = state.copyWith(
        isLastPage: false,
        isLoading: false,
        offset: state.offset + 10,
        chatExchanges: [...state.chatExchanges, ...chatExchanges]);
  }

  List<ChatExchange> get userChatExchanges => state.chatExchanges;
  bool get isLoading => state.isLoading;

  Future<void> loadAllChatExchanges(String id) async {
    //print('Entrando a loadAllChatExchanges!');
    try {
      state = state.copyWith(isLoading: true);
      // Reemplázalo con tu lógica para obtener el userId
      final finalchatExchanges =
          await chatExchangesRepository.getAllChatExchanges(id);
      state =
          state.copyWith(chatExchanges: finalchatExchanges, isLoading: false);
    } catch (e) {
      // Maneja el error según tus necesidades
      state = state.copyWith(isLoading: false);
    }
  }
}

class ChatExchangesState {
  final bool isLastPage;
  final int limit;
  final int offset;
  final bool isLoading;
  final List<ChatExchange> chatExchanges;
  ChatExchangesState({
    this.isLastPage = false,
    this.limit = 10,
    this.offset = 0,
    this.isLoading = false,
    this.chatExchanges = const [],
  });
  ChatExchangesState copyWith({
    bool? isLastPage,
    int? limit,
    int? offset,
    bool? isLoading,
    List<ChatExchange>? chatExchanges,
  }) =>
      ChatExchangesState(
        isLastPage: isLastPage ?? this.isLastPage,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
        isLoading: isLoading ?? this.isLoading,
        chatExchanges: chatExchanges ?? this.chatExchanges,
      );
}
