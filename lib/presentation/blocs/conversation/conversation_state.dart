part of 'conversation_bloc.dart';

sealed class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationEmpty extends ConversationState {
  const ConversationEmpty();
}

class ConversationLoaded extends ConversationState {
  const ConversationLoaded(this.conversations, {this.openedId});

  final List<Conversation> conversations;

  /// Id of the conversation currently open in the chat screen, if any.
  final String? openedId;

  @override
  List<Object?> get props => [conversations, openedId];
}

class ConversationError extends ConversationState {
  const ConversationError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
