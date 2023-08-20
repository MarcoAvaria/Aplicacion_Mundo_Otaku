import 'package:aplicacion_mundo_otaku/presentation/screens/chat/other_message_bubble.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/chat/user_list_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/widget/chat/my_message_bubble.dart';
import 'package:flutter/material.dart';

//import 'all_chats_screen_second.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.user});

  final User user;
  //const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centra el contenido horizontalmente
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(user.profileImage),
              ),
            ),
            const SizedBox(width: 8), // Ajusta el espacio entre la imagen y el texto
            Text(user.username),
            const SizedBox(width: 52),
          ],
        ),
      ),
      body: _ChatView(),
    );
  }
}

class _ChatView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      return (index % 2 == 0)
                          ? const OtherMessageBuble()
                          : const MyMessageBuble();
                    })),
          ],
        ),
      ),
    );
  }
}
