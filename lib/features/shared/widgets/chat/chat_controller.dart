import 'package:get/get.dart';
import 'message.dart';

class ChatController extends GetxController {
  var chatMessages =  <Message>[].obs;
  void addMessage(Message message) {
    print('Añadiendo mensaje: ${message.message}');
    chatMessages.add(message);
  }
}