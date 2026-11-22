import '../entities/conversation.dart';
import '../entities/message.dart';

/// Throws a `Failure` on error.
abstract interface class ConversationRepository {
  Future<List<Conversation>> getConversations();
  Future<Conversation> createConversation(String title);
  Future<void> deleteConversation(String id);
  Future<void> renameConversation(String id, String title);
  Future<List<Message>> getMessages(String conversationId);

  /// Persists the message and bumps the conversation's `updatedAt`.
  Future<void> addMessage(Message message);
}
