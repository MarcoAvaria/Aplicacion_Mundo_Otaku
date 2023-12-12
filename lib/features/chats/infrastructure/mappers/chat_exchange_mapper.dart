import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

class ChatExchangeMapper {
  static ChatExchange jsonToEntity(Map<String, dynamic> json) {
    return ChatExchange(
      id: json['id'] ?? '',
      product1: json['__product1__']['id'] ?? '',
      product2: json['__product2__']['id'] ?? '',
      requester1: json['__requester1__']['id'] ?? '',
      status: json['status'] ?? '',
      messages: List<String>.from(json['messages']
          .map((message) => message['content'].toString())
          .toList(),
      ),
    );
  }
}