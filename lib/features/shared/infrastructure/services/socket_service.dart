import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  String tokencito;
  late io.Socket socket;
  
  SocketService({required this.tokencito}) {
    _initSocket();
    print('Print desde constructor de SocketService');
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
  bool isSubscribed = false;
  // Actualizar el token y los encabezados del socket
  void updateToken(String newToken) {
    tokencito = newToken;
    socket.io.options?['extraHeaders'] = {'authentication': tokencito};
    print('Updated token: $tokencito');
  } 
  void mensajeConectado (String string ){
    if (!isSubscribed) {
      socket.onConnect((_) {
        print('Socket connected successfully! $string');
      });
      isSubscribed = true;
    }
  }
  void enviarMensaje (){
    socket.on('message', (data) => {
      //print(data),
      socket.emit('message-recive', data)
    });
  }
  void disconnect() {
    socket.disconnect();
  }
  void addMessageListener(void Function(String) onMessageReceived) {
    socket.on('message-from-server', (message) {
      onMessageReceived(message);
    });
  }
  // Agrega otras funciones según tus necesidades (enviar mensajes, escuchar eventos, etc.)
  void sendMessage(String text) {
    var messageJson = {
      "message": text,
      "sentByMe": socket.id
    };
    socket.emit('message', messageJson);
  }  
}