import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/message.dart';
import '../blocs/chat/chat_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.conversationId, required this.title, super.key});

  final String conversationId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(param1: conversationId)..add(const ChatStarted()),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const _ChatView(),
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final messages = state.messages;
        return Column(
          children: [
            Expanded(
              child: state.status == ChatStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? const Center(child: Text('Say hello to start the conversation.'))
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          // +1 slot for the typing indicator while waiting.
                          itemCount: messages.length + (state.isSending ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (state.isSending && i == 0) return const TypingIndicator();
                            final index = messages.length - 1 - (state.isSending ? i - 1 : i);
                            return MessageBubble(message: messages[index]);
                          },
                        ),
            ),
            if (state.status == ChatStatus.error && state.failure != null)
              _ErrorBanner(
                message: state.failure!.message,
                // Retry only makes sense when the last message is an unanswered user message.
                onRetry: messages.isNotEmpty && messages.last.role == MessageRole.user
                    ? () => context.read<ChatBloc>().add(const ChatRetried())
                    : null,
              ),
            MessageComposer(
              enabled: !state.isSending,
              onSend: (text) => context.read<ChatBloc>().add(ChatMessageSent(text)),
            ),
          ],
        );
      },
    );
  }
}

/// Inline error shown above the composer; clears on the next send.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
