import 'dart:async';

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../shared.dart';

class SocketService {
  String tokencito;
  String sendBy;
  late io.Socket socket;
  String chatExchangeId;
  //String productId;
  SocketService(
      {required this.tokencito,
      required this.chatExchangeId, 
      required this.sendBy,
      //required this.productId
  }) {
    _initSocket();
    //print('Print desde constructor de SocketService');
  }

  void _initSocket() {
    final uri = Uri.parse(Environment.apiUrl.replaceAll('/api', ''));

    // Añadir parámetros a la URL del socket
    final query = {
      'chatExchangeId': chatExchangeId,
      //'productId': productId,
      'productId': tokencito,
      'sendBy': sendBy,
    };

    // Convertir el objeto Uri a una cadena utilizando toString()
    final urlString = uri.replace(queryParameters: query).toString();
    print({urlString});

    socket = io.io(
      urlString, // Usar la cadena resultante
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'authentication': tokencito})
          .disableAutoConnect()
          .build(),
    );

    socket.connect();
  }

  

  bool isConnected = false;
  // Actualizar el token y los encabezados del socket
  void updateToken(String newToken) {
    tokencito = newToken;
    socket.io.options?['extraHeaders'] = {'authentication': tokencito};
    print('Updated token: $tokencito');
  }

  void mensajeConectado(String string) {
    if (!isConnected) {
      
      socket.once('connect', (_) {
        print('Socket connected successfully! $string');
      });

      isConnected = true;
    }
  }

  void recibirMensaje(ChatController chatController) {
    if (!isConnected) {
      socket.once('message-from-server', (data) {
        print('Mensaje recibido desde el servidorSEGUNDO: $data');
        if (data is Map<String, dynamic>) {
          var receivedMessage = Message.fromJson(data);
          chatController.addMessage(receivedMessage);
          print(receivedMessage.message);
        } else {
          print('El mensaje no es un mapa válido.');
        }
      });
    }
  }

  void cambiarEstado() {
    if (!isConnected) {
      print('Ya esta conectado');
    }
    isConnected = true;
  }

  void enviarMensaje() {
    if (!isConnected) {
      socket.on(
          'message',
          (data) => {
                //print(data),
                socket.emit('message-recive', data)
              });
    }
  }

  void disconnect() {
    print('Se ha desconectado desde -void disconnect()- ');
    socket.disconnect();
  }

  void sendMessage(
      String message, ChatController chatController, String conversacionId, String sendBy) {
    // Asegúrate de que el socket esté conectado
    if (socket.connected) {
      // Enviar el mensaje al servidor
      socket.emit('message-from-client', {
        'content': message,
        'chatExchangeId': conversacionId,
        'sendBy': sendBy,
      });
    } else {
      print('Socket is not connected. Cannot send message.');
    }
  }

  Future<void> _reconnectSocket() async {
    final completer = Completer<void>();

    print('Socket is not connected. Attempting to reconnect...');

    socket.connect();
    socket.once('connect', (_) {
      print('Reconnection successful.');
      completer.complete();
    });

    return completer.future;
  }

  void setUpSocketListener(
      SocketService socketService, ChatController chatController) {
    socketService.socket.on('message-from-server', (data) {
      print(data);
      chatController.chatMessages.add(Message.fromJson(data));
    });
  }
}
