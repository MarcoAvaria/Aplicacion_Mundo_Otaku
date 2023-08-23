import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';

class ChatProvider extends ChangeNotifier {

  List<Message> messageList = [
    Message(text: 'Hola!', fromWho: FromWho.me ),
    Message(text: 'Ya regresaste del trabajo?', fromWho: FromWho.me ),
  ];

  Future<void> sendMessage( String text ) async {
    // TODO implementar método 
  }
}