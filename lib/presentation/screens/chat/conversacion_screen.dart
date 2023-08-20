import 'package:flutter/material.dart';

class ConversacionScreen extends StatelessWidget {
  final String profileImage;
  final String username;

  const ConversacionScreen({super.key, 
    required this.profileImage,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dummyMessages.length,
              reverse: true, // Show messages in descending order
              itemBuilder: (context, index) {
                final message = dummyMessages[index];
                return MessageItem(
                  isMe: message.isMe,
                  message: message.message,
                  time: message.time,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Send the message
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;

  const MessageItem({super.key, 
    required this.isMe,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class Message {
  final bool isMe;
  final String message;
  final String time;

  Message({
    required this.isMe,
    required this.message,
    required this.time,
  });
}

final List<Message> dummyMessages = [
  Message(
    isMe: false,
    message: 'Hey there!',
    time: '10:30 AM',
  ),
  Message(
    isMe: true,
    message: 'Hello! How are you?',
    time: '11:00 AM',
  ),
  // Add more dummy messages here
];