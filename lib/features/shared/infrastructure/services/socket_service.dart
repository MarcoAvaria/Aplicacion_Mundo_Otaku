import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../shared.dart';

class SocketService {
  String tokencito;
  late io.Socket socket;
  SocketService({required this.tokencito}) {
    _initSocket();
    //print('Print desde constructor de SocketService');
  }
  void _initSocket() {
    socket = io.io(
      Environment.apiUrl.replaceAll('/api', ''),
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
      if (!socket.connected) {
        socket.connect();
      }
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
    socket.disconnect();
  }
  void sendMessage(
      String text, SocketService socketService, ChatController chatController) {
    var messageJson = {"message": text, "sentByMe": socketService.socket.id};
    socketService.socket.emit('message-from-client', messageJson);
  }
  void setUpSocketListener(
      SocketService socketService, ChatController chatController) {
    socketService.socket.on('message-from-server', (data) {
      print(data);
      chatController.chatMessages.add(Message.fromJson(data));
    });
  }
}