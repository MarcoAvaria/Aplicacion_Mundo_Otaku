/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../shared/shared.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerWidget {
  static const String name = 'chatscreen';
  final SocketService socketService;
  final String conversacionId;
  final String miProductId;

  ChatScreen(
      {super.key, required this.conversacionId, required this.miProductId})
      : socketService = SocketService(
            tokencito: miProductId,
            chatExchangeId: conversacionId,
            productId: miProductId);

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider(miProductId));

    if (productState.product == null) {
      // Muestra un indicador de carga mientras se carga el estado del producto
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // Aquí, productState y productState.product son seguros de usar
      final product = productState.product!;
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(product.images.first),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
        body: _ChatView(
          productId: miProductId,
          socketService: socketService,
          conversacionId: conversacionId,
        ),
      );
    }
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final String productId;
  final SocketService socketService;
  final String conversacionId;

  const _ChatView({
    required this.productId,
    required this.socketService,
    required this.conversacionId,
  });

  @override
  _ChatViewState createState() => _ChatViewState(
        productId: productId,
        socketService: socketService,
        conversacionId: conversacionId,
      );
}

class _ChatViewState extends ConsumerState {
  final SocketService socketService;
  final String productId;
  final String conversacionId;

  late ChatController chatController;

  _ChatViewState({
    required this.productId,
    required this.socketService,
    required this.conversacionId,
  }) : chatController =
            ChatController(); // Inicializa chatController directamente en el constructor

  late final TextEditingController msgInputController = TextEditingController();

  @override
  void dispose() {
    // Desconectar el socket al salir de la pantalla
    if (socketService.isConnected) {
      socketService.disconnect();
      socketService.socket.off('message-from-server');
    }
    super.dispose();
    print('Hola desde void dispose()');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mueve la lógica de conexión y registro del listener aquí
    socketService.updateToken(productId);
    _connectSocketIfNotConnected();
    socketService.mensajeConectado("Hola desde ChatScreen 111");
    chatController = ChatController(); // Inicializa chatController aquí
    print('Debería aparecer una sola vez');
  }

  void _connectSocketIfNotConnected() {
    if (!socketService.isConnected) {
      print('Socket is not connected. Connecting...');
      socketService.socket.connect();
      socketService.isConnected = true;
    }
    _setUpSocketListener();
  }

  // Cambia la firma de la función _handleMessage
  void _handleMessage(dynamic data) {
    print(data);
    if (data is Map<String, dynamic>) {
      var receivedMessage = Message.fromJson(data);
      chatController.handleMessage(receivedMessage);
      setState(() {});
    } else {
      print('El mensaje no es un mapa válido.');
    }
  }

  void _setUpSocketListener() {
  socketService.getSocketForEvent('message-from-server', _handleMessage);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Expanded(
              flex: 9,
              child: Obx(
                () => ListView.builder(
                  itemCount: chatController.chatMessages.length,
                  itemBuilder: (context, index) {
                    print('Construyendo índice $index');
                    Message currentItem = chatController.chatMessages[index];
                    return MessageItem(
                      sentByMe: (productId == socketService.tokencito),
                      message: currentItem.message,
                    );
                  },
                ),
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
                        color: Colors.lime.shade800,
                      ),
                      child: IconButton(
                        onPressed: () {
                          socketService.sendMessage(
                            msgInputController.text,
                            chatController,
                            conversacionId,
                          );
                          print(
                              'Antes de borrar - Mensaje enviado correctamente: ${msgInputController.text}');
                          msgInputController.text = '';
                          print(
                              'Después de borrar - Mensaje enviado correctamente: ${msgInputController.text}');
                        },
                        icon: const Icon(Icons.send, color: Colors.white60),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            Text(
              "1:10 AM",
              style: TextStyle(
                color:
                    sentByMe ? Colors.amber.shade200 : Colors.purple.shade300,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

*/