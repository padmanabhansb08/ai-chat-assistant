import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/ai_repository.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/settings_repository.dart';

/// Persists the user's message, asks the configured provider for a reply with
/// the full conversation as context, persists the reply and returns it.
///
/// The user message is stored *before* the network call so it survives
/// failures and offline use. On retry the message is already stored, so pass
/// `persistUserMessage: false` to avoid duplicating it.
class SendMessage {
  const SendMessage(this._conversations, this._ai, this._settings);

  final ConversationRepository _conversations;
  final AiRepository _ai;
  final SettingsRepository _settings;

  static const _uuid = Uuid();
  static const maxTitleLength = 40;

  Future<Message> call({
    required Message userMessage,
    bool persistUserMessage = true,
  }) async {
    final conversationId = userMessage.conversationId;
    if (persistUserMessage) {
      await _conversations.addMessage(userMessage);
    }

    final history = await _conversations.getMessages(conversationId);
    if (persistUserMessage && history.length == 1) {
      // First message of the conversation: use it as the title.
      await _conversations.renameConversation(
        conversationId,
        titleFrom(userMessage.content),
      );
    }

    final config = await _settings.getProviderConfig();
    if (!config.isComplete) throw const ConfigFailure();

    final text = await _ai.complete(config: config, history: history);

    final reply = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: text,
      timestamp: DateTime.now(),
    );
    await _conversations.addMessage(reply);
    return reply;
  }

  /// Single-line title, truncated with an ellipsis.
  static String titleFrom(String content) {
    final oneLine = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.length <= maxTitleLength) return oneLine;
    return '${oneLine.substring(0, maxTitleLength - 1).trimRight()}…';
  }
}
