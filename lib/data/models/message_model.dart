import '../../domain/entities/message.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromEntity(Message m) => MessageModel(
        id: m.id,
        conversationId: m.conversationId,
        role: m.role.name,
        content: m.content,
        timestamp: m.timestamp,
      );

  factory MessageModel.fromMap(Map<String, Object?> map) => MessageModel(
        id: map['id']! as String,
        conversationId: map['conversation_id']! as String,
        role: map['role']! as String,
        content: map['content']! as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
      );

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime timestamp;

  Map<String, Object?> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        role: MessageRole.values.byName(role),
        content: content,
        timestamp: timestamp,
      );
}
