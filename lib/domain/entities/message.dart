import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, conversationId, role, content, timestamp];
}
