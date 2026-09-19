class Message {
  final String message;
  final String sendBy;
  final DateTime timestamp;

  const Message(
      {required this.message, required this.sendBy, required this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: (json['content'] ?? json['message'] ?? '').toString(),
      sendBy: (json['sendBy'] ?? json['userId'] ?? '').toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
