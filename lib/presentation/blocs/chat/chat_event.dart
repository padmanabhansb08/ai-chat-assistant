part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the stored history for this bloc's conversation.
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// Re-sends the last user message after a failure, without storing it twice.
class ChatRetried extends ChatEvent {
  const ChatRetried();
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}
