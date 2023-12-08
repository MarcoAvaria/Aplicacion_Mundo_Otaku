import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';

class ChatExchangeMapper {
  
  static jsonToEntity( Map<String, dynamic> json )=> ChatExchange(
    id:json['id'] ?? '',
    product1: json['__product1__']['id'] ?? '',
    product2: json['__product2__']['id'] ?? '',
    requester1: json['__requester1__']['id'] ?? '',
    messages: List<String>.from( json['messages'].map( (message) => message ) ), 
  );
}