//import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
//import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchange_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../shared/shared.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerWidget {
  static const String name = 'chatscreen';
  
  //final String productId;
  final String conversacionId;
  final String miProductId;
  final String otroProductId;
  final SocketService socketService;

  ChatScreen({
    super.key,
    required this.miProductId,
    required this.otroProductId,
    required this.conversacionId,
    //required this.socketService,
    SocketService? socketService,
  }): socketService = socketService ?? SocketService(
        tokencito: miProductId,
        chatExchangeId: conversacionId,
        sendBy: miProductId,
      );
  
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /*
  ChatScreen(
      {super.key,
      required this.miProductId,
      required this.otroProductId,
      required this.conversacionId}) //, required this.miProductId})
      : socketService = SocketService(
            tokencito: miProductId,
            chatExchangeId: conversacionId,
            sendBy: miProductId,
            ); //, productId: miProductId);

  */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // IMPORTANTE: chatController se ocupa de todas formas...
    // ... Aquí lo que es registrarlo
    final chatController = Get.put(ChatController());
    final sendBy = miProductId;
    print('Un print al comienzo, no debería repetirse');
    final productState = ref.watch(productProvider(miProductId));
    final productState2 = ref.watch(productProvider(otroProductId));

    if (productState.product == null || productState2.product == null) {
      // Muestra un indicador de carga centrado mientras se carga el estado del producto
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      final product2 = productState2.product!; 
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(product2.images.first),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                productState2.product!.title,
                style: const TextStyle(fontSize: 15),
              )),
              const SizedBox(width: 52),
            ],
          ),
        ),
        body: _ChatView(miProductId, socketService, conversacionId, sendBy),
      );
    }
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final String productId;
  final String conversacionId;
  final String sendBy;
  final SocketService socketService;
  const _ChatView(this.productId, this.socketService, this.conversacionId, this.sendBy);
  @override
  _ChatViewState createState() =>
      _ChatViewState(productId, socketService, conversacionId, sendBy);
}

class _ChatViewState extends ConsumerState {
  final SocketService socketService;
  final String productId;
  final String conversacionId;
  final String sendBy;
  ChatController chatController = Get.find<ChatController>();
  _ChatViewState(this.productId, this.socketService, this.conversacionId, this.sendBy);
  @override
  void dispose() {
    // Desconectar el socket al salir de la pantalla
    socketService.disconnect();
    socketService.socket.off('message-from-server');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //socketService.disconnect();
    //socketService.updateToken(productId);
    if (!socketService.socket.connected) {
      //print('Socket is not connected. Connecting...');
      socketService.socket.connect();
    }
    ChatController chatController = Get.find<ChatController>();

    socketService.socket.on('message-from-server', (data) {
      if (data is Map<String, dynamic>) {
        var receivedMessage = Message.fromJson(data);
        chatController.addMessage(receivedMessage);
      } else {
        print('El mensaje no es un mapa válido.');
      }
    });
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
                  print('Este es el productId: $productId');
                  print('Este es el socketService.tokencito ${socketService.tokencito}');
                  print('-------------currentItem.sendBy: ${currentItem.sendBy}');
                  return MessageItem(
                    //sentByMe: (productId == socketService.tokencito),
                    //sentByMe: (productId == currentItem.sendBy),
                    sentByMe: (productId == currentItem.sendBy),
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
                                  chatController, conversacionId, sendBy);
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
                  fontSize: 12,
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