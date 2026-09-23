import 'package:aplicacion_mundo_otaku/features/chats/domain/datasources/chat_exchanges_datasource.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';

class ChatExchangesRepositoryImpl extends ChatExchangesRepository {
  final ChatExchangeDatasource datasource;

  ChatExchangesRepositoryImpl(this.datasource);

  @override
  Future<ChatExchange> createChatExchange(
      Map<String, dynamic> chatExchangeLike) {
    return datasource.createChatExchange(chatExchangeLike);
  }

  @override
  Future<ChatExchange> changeChatExchangeStatus(String id, String status) {
    return datasource.changeChatExchangeStatus(id, status);
  }

  @override
  Future<void> markChatExchangeAsRead(String id) {
    return datasource.markChatExchangeAsRead(id);
  }

  @override
  Future<ChatExchange> getChatExchangeById(String id) {
    return datasource.getChatExchangeById(id);
  }

  @override
  Future<List<ChatExchange>> getChatExchangesByPage(
      {int limit = 10, int offset = 0}) {
    return datasource.getChatExchangeByPage(limit: limit, offset: offset);
  }

  @override
  Future<List<ChatExchange>> getAllChatExchanges(String id) {
    return datasource.getAllChatExchanges(id);
  }
}
