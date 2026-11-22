import '../../domain/entities/conversation.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromEntity(Conversation c) => ConversationModel(
        id: c.id,
        title: c.title,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  factory ConversationModel.fromMap(Map<String, Object?> map) => ConversationModel(
        id: map['id']! as String,
        title: map['title']! as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      );

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  Conversation toEntity() => Conversation(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
