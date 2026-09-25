import 'dart:async';

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/providers.dart';
import '../../../chats/presentation/providers/chat_exchange_provider.dart';
import '../../../chats/presentation/providers/chat_read_marks_provider.dart';
import '../../../shared/shared.dart';
import '../../domain/domain.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerWidget {
  static const String name = 'chatscreen';

  final String conversacionId;
  final String miProductId;
  final String otroProductId;

  const ChatScreen({
    super.key,
    required this.miProductId,
    required this.otroProductId,
    required this.conversacionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider(miProductId));
    final otherProductState = ref.watch(productProvider(otroProductId));
    final exchangeState = ref.watch(chatExchangeProvider(conversacionId));

    final tokens = InkTokens.of(context);

    if (productState.product == null ||
        otherProductState.product == null ||
        exchangeState.chatExchange == null) {
      return Scaffold(
        backgroundColor: tokens.paper,
        body: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.halftone),
            ),
          ),
        ),
      );
    }

    final otherProduct = otherProductState.product!;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: SafeArea(
        child: Column(
          children: [
            _InkChatHeader(
              tokens: tokens,
              product: otherProduct,
              isSaving: exchangeState.isSaving,
              canChangeStatus:
                  exchangeState.chatExchange?.status == 'inProgress',
              onSelected: (status) =>
                  _confirmStatusChange(context, ref, status),
            ),
            Expanded(child: _ChatView(conversacionId: conversacionId)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final isCompleted = status == 'done';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCompleted ? '¿Completar intercambio?' : '¿Cancelar intercambio?',
        ),
        content: Text(
          isCompleted
              ? 'El chat se cerrará y el intercambio quedará registrado como completado.'
              : 'El chat se cerrará y el intercambio quedará registrado como cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isCompleted ? 'Completar' : 'Cancelar intercambio'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(chatExchangeProvider(conversacionId).notifier)
          .updateChatExchangeStatus(status);
      // Antes se invalidaba `chatExchangesProvider` aquí, lo que dejaba la
      // lista vacía un instante y hacía parpadear el "Cargando
      // intercambios...". Ahora basta con volver: la lista de chats se recarga
      // al recibir el control (`ExchangeListRefresh.pushAndRefresh`).
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted ? 'Intercambio completado.' : 'Intercambio cancelado.',
          ),
        ),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible actualizar el intercambio.'),
        ),
      );
    }
  }
}

/// Cabecera del chat en la dirección "Tinta y Neón".
///
/// Reemplaza al `AppBar` de Material sin tocar el cuerpo de la conversación.
/// Conserva las anclas del recorrido: el menú de opciones se localiza por su
/// rol con el nombre "Opciones del intercambio", y sus dos entradas mantienen
/// sus textos. No agrega ningún campo de texto: la pantalla tiene que seguir
/// teniendo un único `textbox`, que es el de escribir mensajes.
class _InkChatHeader extends StatelessWidget {
  const _InkChatHeader({
    required this.tokens,
    required this.product,
    required this.isSaving,
    required this.canChangeStatus,
    required this.onSelected,
  });

  final InkTokens tokens;
  final Product product;
  final bool isSaving;
  final bool canChangeStatus;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border(bottom: BorderSide(color: tokens.ink, width: 2)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Volver',
            child: Material(
              color: tokens.panel,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.ink, width: 2.5),
                  ),
                  child: Icon(Icons.arrow_back, size: 18, color: tokens.text),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Container(
            width: 34,
            height: 42,
            decoration: BoxDecoration(
              color: tokens.avatarWash,
              border: Border.all(color: tokens.chipSelectedBorder, width: 2),
            ),
            child: product.images.isEmpty
                ? Icon(Icons.inventory_2_outlined,
                    size: 15, color: tokens.muted)
                : FadeInImage(
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    image: imageProviderForPath(product.images.first),
                    placeholder: const AssetImage('assets/images/no-image.jpg'),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'INTERCAMBIO EN CURSO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                    color: tokens.halftone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.displayStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: tokens.text,
                  ),
                ),
              ],
            ),
          ),
          if (isSaving)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.halftone),
                ),
              ),
            )
          else if (canChangeStatus)
            PopupMenuButton<String>(
              tooltip: 'Opciones del intercambio',
              color: tokens.panel,
              shape: Border.all(color: tokens.ink, width: 2),
              icon: Icon(Icons.more_vert, color: tokens.text),
              onSelected: onSelected,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'done',
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Marcar como completado'),
                  ),
                ),
                PopupMenuItem(
                  value: 'cancelled',
                  child: ListTile(
                    leading: Icon(Icons.cancel_outlined),
                    title: Text('Cancelar intercambio'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final String conversacionId;

  const _ChatView({required this.conversacionId});

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  /// Los mensajes de esta conversación, y de ninguna otra.
  ///
  /// Antes vivían en un `ChatController` de GetX creado una sola vez al
  /// arrancar la app: la lista sobrevivía a la pantalla, y los mensajes de la
  /// última conversación seguían en memoria hasta que se abría otra y
  /// `initState` los borraba. Ahora nacen y mueren con la pantalla.
  final List<Message> _messages = [];
  final socketService = SocketService.instance;
  final inputController = TextEditingController();
  late final String currentUserId;

  /// Espera el historial que pide un refresco manual.
  Completer<void>? _pendingHistory;

  @override
  void initState() {
    super.initState();
    currentUserId = ref.read(authProvider).user?.id ?? '';
    socketService.socket.on('chat-history', _onHistory);
    socketService.socket.on('new-message', _onMessage);
    socketService.socket.on('chat-error', _onChatError);
    socketService.joinChat(widget.conversacionId);
  }

  void _onHistory(dynamic data) {
    final messages = data is Map ? data['messages'] : null;
    if (messages is! List) {
      _completePendingHistory();
      return;
    }
    final parsed = messages
        .whereType<Map>()
        .map((item) => Message.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    // Un evento no debería llegar con la pantalla cerrada, porque `dispose`
    // da de baja los manejadores; si llegara, `setState` lanzaría un error.
    if (mounted) {
      setState(() => _messages
        ..clear()
        ..addAll(parsed));
    }
    _markReadUpTo(parsed.isEmpty ? null : parsed.last.timestamp);
    _completePendingHistory();
  }

  void _onMessage(dynamic data) {
    if (data is! Map) return;
    final message = Message.fromJson(Map<String, dynamic>.from(data));
    if (!mounted) return;
    setState(() => _messages.add(message));
    // Estando dentro de la conversación, lo que llega ya está leído.
    _markReadUpTo(message.timestamp);
  }

  void _markReadUpTo(DateTime? timestamp) {
    if (!mounted) return;
    unawaited(
      ref.read(chatReadMarksProvider.notifier).markReadAt(
            userId: currentUserId,
            exchangeId: widget.conversacionId,
            timestamp: timestamp,
          ),
    );
  }

  void _completePendingHistory() {
    final pending = _pendingHistory;
    _pendingHistory = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  /// Vuelve a pedir el historial al servidor.
  ///
  /// Sirve sobre todo cuando la conexión se cortó y volvió: el socket puede
  /// haberse perdido mensajes mientras tanto.
  Future<void> _refreshHistory() async {
    if (!socketService.isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. No se pudo actualizar.')),
      );
      return;
    }

    _completePendingHistory();
    final pending = Completer<void>();
    _pendingHistory = pending;
    socketService.joinChat(widget.conversacionId);

    // Si la respuesta no llega, el gesto termina igual en vez de quedarse
    // girando para siempre.
    await pending.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => _pendingHistory = null,
    );
  }

  void _onChatError(dynamic data) {
    if (!mounted) return;
    final message = data is Map ? data['message'] : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message?.toString() ?? 'Error en el chat.')),
    );
  }

  @override
  void dispose() {
    _completePendingHistory();
    socketService.leaveChat(widget.conversacionId);
    // Con `off` del servicio y no `socket.off`: si la sesión se cerró con el
    // chat abierto, el socket ya no existe y `socket` lanzaría (T-058).
    socketService.off('chat-history', _onHistory);
    socketService.off('new-message', _onMessage);
    socketService.off('chat-error', _onChatError);
    inputController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final sent =
        socketService.sendMessage(inputController.text, widget.conversacionId);
    if (sent) {
      inputController.clear();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sin conexión. El mensaje no se envió.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: socketService,
      builder: (context, child) => Semantics(
        container: true,
        explicitChildNodes: true,
        label: socketService.isChatReady(widget.conversacionId)
            ? 'Chat conectado'
            : 'Chat sin conexión',
        child: child,
      ),
      child: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final tokens = InkTokens.of(context);
                return RefreshIndicator(
                  onRefresh: _refreshHistory,
                  color: tokens.halftone,
                  backgroundColor: tokens.panel,
                  child: ListView.builder(
                    // El historial tiene que poder arrastrarse aunque
                    // quepa entero, o el gesto de refrescar no existe.
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageItem(
                        sentByMe: currentUserId == message.sendBy,
                        message: message.message,
                        timestamp: message.timestamp,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Builder(
                builder: (context) {
                  final tokens = InkTokens.of(context);
                  return TextField(
                    controller: inputController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje',
                      filled: true,
                      fillColor: tokens.panel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: tokens.ink, width: 2.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: tokens.ink, width: 2.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: tokens.halftone, width: 2.5),
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Enviar mensaje',
                        onPressed: _sendMessage,
                        icon: Icon(Icons.send, color: tokens.halftone),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final bool sentByMe;
  final String message;
  final DateTime timestamp;

  const MessageItem({
    super.key,
    required this.sentByMe,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';

    // El globo propio se tiñe con el contenedor del acento; el neón del modo
    // oscuro queda solo para el borde, nunca como relleno.
    final background = sentByMe ? tokens.chipSelected : tokens.panel;
    final foreground = sentByMe && !isDark ? tokens.onAccent : tokens.text;

    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 13),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: sentByMe ? tokens.chipSelectedBorder : tokens.ink,
            width: tokens.borderWidth,
          ),
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(3, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message, style: TextStyle(fontSize: 14.5, color: foreground)),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: sentByMe && !isDark
                    ? tokens.onAccent.withValues(alpha: 0.8)
                    : tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
