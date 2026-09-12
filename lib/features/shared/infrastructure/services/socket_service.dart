import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'network_status.dart';

class SocketService with ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal() {
    networkStatusChanges.listen(_handleNetworkStatus);
  }

  static SocketService get instance => _instance;

  io.Socket? _socket;
  String? _token;
  String? _pendingChatId;
  String? _joinedChatId;
  bool isConnected = false;

  bool isChatReady(String chatExchangeId) =>
      isConnected && _joinedChatId == chatExchangeId;

  io.Socket get socket {
    final currentSocket = _socket;
    if (currentSocket == null) {
      throw StateError('El socket aún no ha sido inicializado');
    }
    return currentSocket;
  }

  void initialize({required String token}) {
    if (_token == token && _socket != null) {
      if (isNetworkOnline && !socket.connected) socket.connect();
      return;
    }

    disconnect();
    _token = token;
    final socketUrl = Environment.socketUrl;
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
    socket.on('joined-chat', (data) {
      if (data is! Map) return;
      final chatId = data['chatExchangeId']?.toString();
      if (chatId == null || chatId != _pendingChatId) return;
      _setJoinedChat(chatId);
    });
    socket.onDisconnect((_) => _handleDisconnected());
    socket.onConnectError((_) => _handleDisconnected());
    if (isNetworkOnline) socket.connect();
  }

  void joinChat(String chatExchangeId) {
    if (_pendingChatId != chatExchangeId || _joinedChatId != null) {
      _pendingChatId = chatExchangeId;
      _setJoinedChat(null);
    }
    if (isConnected) {
      socket.emit('join-chat', {'chatExchangeId': chatExchangeId});
    }
  }

  void leaveChat(String chatExchangeId) {
    if (_pendingChatId == chatExchangeId) _pendingChatId = null;
    if (_joinedChatId == chatExchangeId) _setJoinedChat(null);
    _socket?.emit('leave-chat', {'chatExchangeId': chatExchangeId});
  }

  bool sendMessage(String content, String chatExchangeId) {
    final message = content.trim();
    if (message.isEmpty || !isNetworkOnline || !isChatReady(chatExchangeId)) {
      return false;
    }
    socket.emit('send-message', {
      'chatExchangeId': chatExchangeId,
      'content': message,
    });
    return true;
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
    _handleDisconnected();
  }

  void _handleDisconnected() {
    final changed = isConnected || _joinedChatId != null;
    isConnected = false;
    _joinedChatId = null;
    if (changed) notifyListeners();
  }

  void _handleNetworkStatus(bool online) {
    final currentSocket = _socket;
    if (!online) {
      currentSocket?.disconnect();
      _handleDisconnected();
      return;
    }

    currentSocket?.connect();
  }

  void _setJoinedChat(String? chatId) {
    if (_joinedChatId == chatId) return;
    _joinedChatId = chatId;
    notifyListeners();
  }

  void _setConnectionState(bool connected) {
    if (isConnected == connected) return;
    isConnected = connected;
    notifyListeners();
  }
}
