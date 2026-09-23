import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'dart:async';

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

  final _exchangeActivity = StreamController<ExchangeActivity>.broadcast();

  /// Avisos de intercambios que **no** tienes abiertos.
  ///
  /// El servidor mete a cada persona en una sala propia al autenticar el
  /// socket, y empuja por ahí un aviso cuando llega un mensaje o cambia el
  /// estado de alguno de sus intercambios. No hace falta unirse a nada: el
  /// socket existe desde que iniciaste sesión, no desde que entraste a un chat.
  ///
  /// El aviso trae lo mínimo, nunca el contenido del mensaje. Quien escucha lo
  /// usa como señal para volver a pedir los datos por los caminos de siempre,
  /// que son los que comprueban permisos.
  Stream<ExchangeActivity> get exchangeActivity => _exchangeActivity.stream;

  /// Si se puede conversar en este intercambio ahora mismo.
  ///
  /// Es **la única** condición: la usan tanto el indicador de la cabecera como
  /// `sendMessage`. Antes el envío exigía además `isNetworkOnline` por su
  /// cuenta, y las dos señales podían discrepar: Socket.IO se reconecta solo,
  /// así que el socket volvía y se unía a la sala mientras `navigator.onLine`
  /// seguía en falso unos instantes. En esa ventana la cabecera decía "Chat
  /// conectado" mientras el envío se habría rechazado en silencio, que es
  /// justo lo que un indicador de estado no debe hacer.
  ///
  /// Se unificó mientras se investigaba T-026. **No era su causa**: la
  /// intermitencia siguió igual después de este cambio. Se conserva porque
  /// tener una sola definición de "se puede enviar" es correcto por sí mismo.
  bool isChatReady(String chatExchangeId) =>
      isNetworkOnline && isConnected && _joinedChatId == chatExchangeId;

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
          // El caché por origen puede conservar el JWT de una sesión cerrada.
          .enableForceNew()
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
    socket.on('exchange-activity', (data) {
      if (data is! Map) return;
      final chatExchangeId = data['chatExchangeId']?.toString();
      if (chatExchangeId == null || chatExchangeId.isEmpty) return;
      _exchangeActivity.add(
        ExchangeActivity(
          chatExchangeId: chatExchangeId,
          esMensaje: data['kind']?.toString() == 'message',
          estado: data['status']?.toString(),
        ),
      );
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
    if (message.isEmpty || !isChatReady(chatExchangeId)) return false;
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

/// Un aviso de que algo pasó en un intercambio.
class ExchangeActivity {
  const ExchangeActivity({
    required this.chatExchangeId,
    required this.esMensaje,
    this.estado,
  });

  final String chatExchangeId;

  /// `true` si llegó un mensaje; `false` si lo que cambió fue el estado.
  final bool esMensaje;

  /// A qué estado pasó el intercambio, cuando el aviso es de estado.
  final String? estado;
}
