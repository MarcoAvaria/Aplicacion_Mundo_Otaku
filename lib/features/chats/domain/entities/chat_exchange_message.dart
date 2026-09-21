/// Un mensaje guardado dentro de un intercambio.
///
/// La API los devuelve en la columna `messages` de `chat_exchanges`, tanto en
/// el detalle de un intercambio como en el listado del usuario. Conservar el
/// autor y la fecha es lo que permite contar los mensajes no leídos sin pedir
/// nada más al servidor.
class ChatExchangeMessage {
  const ChatExchangeMessage({
    required this.content,
    required this.sendBy,
    required this.timestamp,
  });

  final String content;

  /// Identificador de quien lo escribió. Vacío en mensajes antiguos.
  final String sendBy;

  /// Nulo cuando el mensaje no trae fecha, que es el caso de los guardados
  /// antes de que el servidor la incluyera.
  final DateTime? timestamp;

  factory ChatExchangeMessage.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp']?.toString();

    return ChatExchangeMessage(
      content: (json['content'] ?? json['message'] ?? '').toString(),
      sendBy: (json['sendBy'] ?? json['userId'] ?? '').toString(),
      timestamp: rawTimestamp == null ? null : DateTime.tryParse(rawTimestamp),
    );
  }
}
