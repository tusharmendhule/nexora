import '../../../core/models/user.dart';

enum MessageType { text, image }

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final MessageType type;
  final bool isRead;

  bool isMine(String currentUserId) => senderId == currentUserId;

  factory Message.fromApi(Map<String, dynamic> json) {
    return Message(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      senderId: (json['senderId'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
              DateTime.now(),
      type: json['type'] == 'image' ? MessageType.image : MessageType.text,
      isRead: json['isRead'] == true,
    );
  }
}

class Chat {
  const Chat({
    required this.id,
    required this.participant,
    required this.messages,
    this.unread = 0,
  });

  final String id;
  final User participant;
  final List<Message> messages;
  final int unread;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  int get unreadCount => unread;

  factory Chat.fromApi(Map<String, dynamic> json) {
    final last = json['lastMessage'] as Map<String, dynamic>?;
    return Chat(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      participant:
          User.fromApi((json['participant'] as Map<String, dynamic>?) ?? const {}),
      messages: [
        if (last != null) Message.fromApi(last),
      ],
      unread: ((json['unreadCount'] as num?) ?? 0).toInt(),
    );
  }
}
