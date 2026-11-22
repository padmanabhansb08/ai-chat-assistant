import '../entities/conversation.dart';
import '../entities/message.dart';
import '../repositories/conversation_repository.dart';

class GetConversations {
  const GetConversations(this._repository);
  final ConversationRepository _repository;

  Future<List<Conversation>> call() => _repository.getConversations();
}

class CreateConversation {
  const CreateConversation(this._repository);
  final ConversationRepository _repository;

  Future<Conversation> call(String title) => _repository.createConversation(title);
}

class DeleteConversation {
  const DeleteConversation(this._repository);
  final ConversationRepository _repository;

  Future<void> call(String id) => _repository.deleteConversation(id);
}

class GetMessages {
  const GetMessages(this._repository);
  final ConversationRepository _repository;

  Future<List<Message>> call(String conversationId) =>
      _repository.getMessages(conversationId);
}
