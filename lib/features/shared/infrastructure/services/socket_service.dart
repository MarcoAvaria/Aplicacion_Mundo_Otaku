import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService with ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static SocketService get instance => _instance;

  io.Socket? _socket;
  String? _token;
  String? _pendingChatId;
  bool isConnected = false;

  io.Socket get socket {
    final currentSocket = _socket;
    if (currentSocket == null) {
      throw StateError('El socket aún no ha sido inicializado');
    }
    return currentSocket;
  }

  void initialize({required String token}) {
    if (_token == token && _socket != null) {
      if (!socket.connected) socket.connect();
      return;
    }

    disconnect();
    _token = token;
    final socketUrl = Environment.apiUrl.replaceFirst(RegExp(r'/api/?$'), '');
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    socket.on('authenticated', (_) {
      _setConnectionState(true);
      final chatId = _pendingChatId;
      if (chatId != null) {
        socket.emit('join-chat', {'chatExchangeId': chatId});
      }
    });
    socket.onDisconnect((_) => _setConnectionState(false));
    socket.onConnectError((_) => _setConnectionState(false));
    socket.connect();
  }

  void joinChat(String chatExchangeId) {
    _pendingChatId = chatExchangeId;
    if (isConnected) {
      socket.emit('join-chat', {'chatExchangeId': chatExchangeId});
    }
  }

  void leaveChat(String chatExchangeId) {
    if (_pendingChatId == chatExchangeId) _pendingChatId = null;
    _socket?.emit('leave-chat', {'chatExchangeId': chatExchangeId});
  }

  void sendMessage(String content, String chatExchangeId) {
    final message = content.trim();
    if (message.isEmpty || !socket.connected) return;
    socket.emit('send-message', {
      'chatExchangeId': chatExchangeId,
      'content': message,
    });
  }

  void disconnect() {
    final currentSocket = _socket;
    if (currentSocket != null) {
      currentSocket.disconnect();
      currentSocket.dispose();
    }
    _socket = null;
    _token = null;
    _pendingChatId = null;
    _setConnectionState(false);
  }

  void _setConnectionState(bool connected) {
    if (isConnected == connected) return;
    isConnected = connected;
    notifyListeners();
  }
}
