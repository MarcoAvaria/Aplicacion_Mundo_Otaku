import 'package:get/get.dart';
import 'message.dart';

class ChatController extends GetxController {
  var chatMessages =  <Message>[].obs;

  void addMessage(Message message) {
    chatMessages.add(message);
  }
}