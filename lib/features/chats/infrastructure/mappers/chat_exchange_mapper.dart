import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

class ChatExchangeMapper {
  static ChatExchange jsonToEntity(Map<String, dynamic> json) {
    final owner1 = json['owner1'] ?? json['__owner1__'];
    final owner2 = json['owner2'] ?? json['__owner2__'];
    final product1 = json['product1'] ?? json['__product1__'];
    final product2 = json['product2'] ?? json['__product2__'];
    final requester1 = json['requester1'] ?? json['__requester1__'];

    return ChatExchange(
      id: json['id'] ?? '',
      owner1: owner1?['id'] ?? '',
      owner2: owner2?['id'] ?? '',
      product1: product1?['id'] ?? '',
      product2: product2?['id'] ?? '',
      requester1: requester1?['id'] ?? '',
      status: json['status'] ?? '',
      messages: List<String>.from(
        json['messages']
            .map((message) => message['content'].toString())
            .toList(),
      ),
    );
  }
}
