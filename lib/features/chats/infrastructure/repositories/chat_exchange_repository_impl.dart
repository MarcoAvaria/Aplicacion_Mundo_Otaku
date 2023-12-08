import 'package:aplicacion_mundo_otaku/features/chats/domain/datasources/chat_exchanges_datasource.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';

class ChatExchangesRepositoryImpl extends ChatExchangesRepository {

  final ChatExchangeDatasource datasource;

  ChatExchangesRepositoryImpl( this.datasource );

  @override
  Future<ChatExchange> createUpdateChatExchange(Map<String, dynamic> chatExchangeLike) {
    return datasource.createUpdateChatExchange(chatExchangeLike);
  }

  @override
  Future<ChatExchange> getChatExchangeById(String id) {
    return datasource.getChatExchangeById(id);
  }
  
  @override
  Future<List<ChatExchange>> getChatExchangesByPage({int limit = 10, int offset = 0}) {
    return datasource.getChatExchangeByPage(limit: limit, offset: offset);
  }
  
  // Implementar los métodos según tus necesidades
}