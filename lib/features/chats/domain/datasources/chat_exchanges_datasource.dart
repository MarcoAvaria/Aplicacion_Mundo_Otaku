import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

abstract class ChatExchangeDatasource {
  Future<List<ChatExchange>> getChatExchangeByPage(
      {int limit = 10, int offset = 0});

  Future<ChatExchange> getChatExchangeById(String id);

  Future<ChatExchange> changeChatExchangeStatus(String id, String status);

  Future<ChatExchange> createChatExchange(
      Map<String, dynamic> chatExchangeLike);

  Future<List<ChatExchange>> getAllChatExchanges(String id);
}
