import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

abstract class ChatExchangesRepository {

  Future<List<ChatExchange>> getChatExchangesByPage({ int limit = 10, int offset = 0 });

  Future<ChatExchange> getChatExchangeById(String id);
  
  //Future<List<ChatExchange>> getChatExchanges();
  
  Future<ChatExchange> createUpdateChatExchange(Map<String,dynamic> chatExchangeLike );
  // Agregar otros métodos según sea necesario
}