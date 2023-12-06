import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../shared/shared.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerWidget {
  static const String name = 'chatscreen';
  final String productId;
  final SocketService socketService;
  ChatScreen({super.key, required this.productId})
      : socketService = SocketService(tokencito: productId);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Un print al comienzo, no debería repetirse');
    final productState = ref.watch(productProvider(productId));
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centra el contenido horizontalmente
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: CircleAvatar(
                backgroundImage:
                    NetworkImage(productState.product!.images.first),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              productState.product!.title,
              style: const TextStyle(fontSize: 15),
            )),
            const SizedBox(width: 52),
          ],
        ),
      ),
      body: _ChatView(productId, socketService),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final String productId;
  final SocketService socketService;
  const _ChatView(this.productId, this.socketService);
  @override
  _ChatViewState createState() => _ChatViewState(productId, socketService);
}

class _ChatViewState extends ConsumerState {
  final SocketService socketService;
  final String productId;
  ChatController chatController = Get.find<ChatController>();
  _ChatViewState(this.productId, this.socketService);
  @override
  void dispose() {
    // Desconectar el socket al salir de la pantalla
    socketService.disconnect();
    socketService.socket.off('message-from-server');
    super.dispose();
    print('Hola desde void dispose()');
  }

  @override
  void initState() {
    super.initState();
    socketService.disconnect();
    socketService.updateToken(productId);
    if (!socketService.socket.connected) {
      print('Socket is not connected. Connecting...');
      socketService.socket.connect();
    }
    final ChatController chatController = Get.find<ChatController>();
    print('Debería aparecer una sola vez');
    socketService.mensajeConectado("Hola desde ChatScreen");

    //socketService.recibirMensaje(chatController);

    
    socketService.socket.on('message-from-server', (data) {
      if (data is Map<String, dynamic>) {
        var receivedMessage = Message.fromJson(data);
        //chatController.addMessage(receivedMessage);
        
        print('esta es la data: $data');
        print('esta es la receivedMessage: $receivedMessage');
        //chatController.chatMessages.add(receivedMessage);
        chatController.addMessage(receivedMessage);
        print('receivedMessage: ' + receivedMessage.message);
        print('PRIMERA INSTANCIA del array: ' + chatController.chatMessages.first.message);
        print('ÚLTIMA INSTANCIA del array: ' + chatController.chatMessages.last.message);
        print('SentbyMe???: ' + chatController.chatMessages.last.sentByMe);
        print('socketService.tokencito: ' + socketService.tokencito);
        print('socketService.socket.id: ' + (socketService.socket.id??''));
        print('product.id: ' + productId);
        
        //print(chatController.chatMessages.);
      } else {
        print('El mensaje no es un mapa válido.');
      }}
    );
    
  }

  @override
  Widget build(BuildContext context) {
    //ChatController chatController = ChatController();
    TextEditingController msgInputController = TextEditingController();
    //socketService.mensajeConectado("Hola desde ChatScreen en Widget build(BuildContext context)");
    return Scaffold(
        body: Container(
      child: Column(children: [
        Expanded(
          flex: 9,
          child: Obx(
            () => ListView.builder(
                itemCount: chatController.chatMessages.length,
                itemBuilder: (context, index) {
                  Message currentItem = chatController.chatMessages[index];
                  return MessageItem(
                    sentByMe: (productId == socketService.tokencito),
                    //sentByMe: true,
                    message: currentItem.message,
                  );
                }),
          ),
        ),
        Expanded(
            child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.purple.shade300,
                child: TextField(
                  style: TextStyle(
                    color: Colors.amber.shade200,
                  ),
                  cursorColor: Colors.lightGreenAccent.shade100,
                  controller: msgInputController,
                  decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: Container(
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.lime.shade800),
                          child: IconButton(
                            onPressed: () {
                              //sendMessage(msgInputController.text);
                              socketService.sendMessage(msgInputController.text,
                                  socketService, chatController);
                              msgInputController.text = '';
                            },
                            icon: const Icon(Icons.send, color: Colors.white60),
                          ))),
                ))),
      ]),
    ));
  }
}

class MessageItem extends StatelessWidget {
  const MessageItem({super.key, required this.sentByMe, required this.message});
  final bool sentByMe;
  final String message;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 10,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: sentByMe ? Colors.purple.shade300 : Colors.amber.shade200,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                message,
                style: TextStyle(
                  color:
                      sentByMe ? Colors.amber.shade200 : Colors.purple.shade300,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 5),
              Text("1:10 AM",
                  style: TextStyle(
                    color: sentByMe
                        ? Colors.amber.shade200
                        : Colors.purple.shade300,
                    fontSize: 10,
                  )),
            ],
          )),
    );
  }
}