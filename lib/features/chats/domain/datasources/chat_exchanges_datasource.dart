import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

abstract class ChatExchangeDatasource {
  Future<List<ChatExchange>> getChatExchangeByPage(
      {int limit = 10, int offset = 0});

  Future<ChatExchange> getChatExchangeById(String id);

  Future<ChatExchange> changeChatExchangeStatus(String id, String status);

  /// Anota en el servidor hasta dónde leyó quien está usando la aplicación.
  ///
  /// No falla hacia afuera si la petición no sale: la marca local ya dejó el
  /// contador en cero, y el servidor se pondrá al día la próxima vez. Perder
  /// este aviso es una molestia menor, no un error que deba interrumpir a nadie.
  Future<void> markChatExchangeAsRead(String id);

  Future<ChatExchange> createChatExchange(
      Map<String, dynamic> chatExchangeLike);

  Future<List<ChatExchange>> getAllChatExchanges(String id);
}
