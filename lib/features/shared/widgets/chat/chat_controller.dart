import 'package:get/get.dart';
import 'message.dart';

class ChatController extends GetxController {
  final chatMessages = <Message>[].obs;
  void addMessage(Message message) {
    chatMessages.add(message);
  }

  void replaceMessages(Iterable<Message> messages) {
    chatMessages.assignAll(messages);
  }

  void clearMessages() {
    chatMessages.clear();
  }
}
