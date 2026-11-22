import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../datasources/conversation_local_data_source.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._local);

  final ConversationLocalDataSource _local;
  static const _uuid = Uuid();

  @override
  Future<List<Conversation>> getConversations() => _guard(() async {
        final models = await _local.getConversations();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Conversation> createConversation(String title) => _guard(() async {
        final now = DateTime.now();
        final model = ConversationModel(
          id: _uuid.v4(),
          title: title,
          createdAt: now,
          updatedAt: now,
        );
        await _local.insertConversation(model);
        return model.toEntity();
      });

  @override
  Future<void> deleteConversation(String id) =>
      _guard(() => _local.deleteConversation(id));

  @override
  Future<void> renameConversation(String id, String title) =>
      _guard(() => _local.renameConversation(id, title));

  @override
  Future<List<Message>> getMessages(String conversationId) => _guard(() async {
        final models = await _local.getMessages(conversationId);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<void> addMessage(Message message) =>
      _guard(() => _local.insertMessage(MessageModel.fromEntity(message)));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Failure {
      rethrow;
    } catch (_) {
      throw const StorageFailure();
    }
  }
}
