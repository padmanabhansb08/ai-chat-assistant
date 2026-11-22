part of 'conversation_bloc.dart';

sealed class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class ConversationsRequested extends ConversationEvent {
  const ConversationsRequested();
}

/// Creates a conversation and opens it.
class ConversationCreated extends ConversationEvent {
  const ConversationCreated(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

class ConversationOpened extends ConversationEvent {
  const ConversationOpened(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// The chat screen was popped; no conversation is open any more.
class ConversationClosed extends ConversationEvent {
  const ConversationClosed();
}

class ConversationDeleted extends ConversationEvent {
  const ConversationDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
