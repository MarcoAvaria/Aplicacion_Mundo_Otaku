import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
//import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';

abstract class ChatExchangeDatasource {

  Future<List<ChatExchange>> getChatExchangeByPage({ int limit = 10, int offset = 0 });
  
  Future<ChatExchange> getChatExchangeById(String id);

  Future<List<ChatExchange>> searchChatExchangeByTerm( String term );

  Future<ChatExchange> createUpdateChatExchange( Map<String,dynamic> chatExchangeLike );
}