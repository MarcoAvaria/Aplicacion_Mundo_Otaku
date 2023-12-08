/*
import 'package:aplicacion_mundo_otaku/features/auth/domain/entities/message.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/chat/other_message_bubble.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/screens.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/chat/my_message_bubble.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/message_field_box.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

//import 'all_chats_screen_second.dart';

class AnotherChatScreen extends StatelessWidget {

  //static const String name = 'chat_screen';

  const AnotherChatScreen({super.key, required this.user});

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
            const SizedBox(
                width: 8), // Ajusta el espacio entre la imagen y el texto
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
    
    final chatProvider = context.watch<ChatProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
                    controller: chatProvider.chatScrollController,
                    itemCount: chatProvider.messageList.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messageList[index];

                      return (message.fromWho == FromWho.other)
                          ? const OtherMessageBuble()
                          : MyMessageBuble( message: message);
                    })),
            // Text box
            MessageFieldBox(
              //onValue: (value) => chatProvider.sendMessage(value) ,
              onValue: chatProvider.sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

*/

//TODO: PARA BORRAR !!!
