import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../auth/presentation/providers/providers.dart';
import '../../../chats/presentation/providers/chat_exchange_provider.dart';
import '../../../chats/presentation/providers/chat_exchanges_provider.dart';
import '../../../shared/shared.dart';
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

    if (productState.product == null ||
        otherProductState.product == null ||
        exchangeState.chatExchange == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final otherProduct = otherProductState.product!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: otherProduct.images.isEmpty
                  ? null
                  : NetworkImage(otherProduct.images.first),
              child: otherProduct.images.isEmpty
                  ? const Icon(Icons.inventory_2_outlined)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(otherProduct.title,
                  style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
        actions: [
          if (exchangeState.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (exchangeState.chatExchange?.status == 'inProgress')
            PopupMenuButton<String>(
              tooltip: 'Opciones del intercambio',
              onSelected: (status) =>
                  _confirmStatusChange(context, ref, status),
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
      body: _ChatView(conversacionId: conversacionId),
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
      ref.invalidate(chatExchangesProvider);
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

class _ChatView extends ConsumerStatefulWidget {
  final String conversacionId;

  const _ChatView({required this.conversacionId});

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final chatController = Get.find<ChatController>();
  final socketService = SocketService.instance;
  final inputController = TextEditingController();
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = ref.read(authProvider).user?.id ?? '';
    chatController.clearMessages();
    socketService.socket.on('chat-history', _onHistory);
    socketService.socket.on('new-message', _onMessage);
    socketService.socket.on('chat-error', _onChatError);
    socketService.joinChat(widget.conversacionId);
  }

  void _onHistory(dynamic data) {
    final messages = data is Map ? data['messages'] : null;
    if (messages is! List) return;
    chatController.replaceMessages(
      messages.whereType<Map>().map(
            (item) => Message.fromJson(Map<String, dynamic>.from(item)),
          ),
    );
  }

  void _onMessage(dynamic data) {
    if (data is! Map) return;
    chatController.addMessage(
      Message.fromJson(Map<String, dynamic>.from(data)),
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
    socketService.leaveChat(widget.conversacionId);
    socketService.socket.off('chat-history', _onHistory);
    socketService.socket.off('new-message', _onMessage);
    socketService.socket.off('chat-error', _onChatError);
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
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: chatController.chatMessages.length,
                itemBuilder: (context, index) {
                  final message = chatController.chatMessages[index];
                  return MessageItem(
                    sentByMe: currentUserId == message.sendBy,
                    message: message.message,
                    timestamp: message.timestamp,
                  );
                },
              ),
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
                        borderSide:
                            BorderSide(color: tokens.ink, width: 2.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: tokens.ink, width: 2.5),
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
    final foreground =
        sentByMe && !isDark ? tokens.onAccent : tokens.text;

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
                    ? tokens.onAccent.withOpacity(0.8)
                    : tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
