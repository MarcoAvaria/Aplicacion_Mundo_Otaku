import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

abstract class ChatExchangesRepository {
  Future<List<ChatExchange>> getChatExchangesByPage(
      {int limit = 10, int offset = 0});

  Future<ChatExchange> getChatExchangeById(String id);

  Future<ChatExchange> changeChatExchangeStatus(String id, String status);
  Future<List<ChatExchange>> getAllChatExchanges(String id);

  Future<ChatExchange> createChatExchange(
      Map<String, dynamic> chatExchangeLike);
}
