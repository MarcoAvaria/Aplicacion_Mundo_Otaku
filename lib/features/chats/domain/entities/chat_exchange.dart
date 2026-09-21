import 'chat_exchange_message.dart';

class ChatExchange {
  late String id;
  late String owner1;
  late String owner2;
  late String product1;
  late String product2;
  late String requester1;
  late List<ChatExchangeMessage> messages;
  late String status;

  ChatExchange({
    required this.id,
    required this.owner1,
    required this.owner2,
    required this.product1,
    required this.product2,
    required this.requester1,
    required this.messages,
    required this.status,
  });
}
