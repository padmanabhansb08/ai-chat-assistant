part of 'chat_bloc.dart';

/// initial -> ChatInitial, loading history -> ChatLoading,
/// awaiting AI reply -> sending (typing indicator), done -> ChatSuccess,
/// failure -> ChatError. The message list is kept in every status so an error
/// never wipes the conversation from the screen.
enum ChatStatus { initial, loading, sending, success, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.failure,
  });

  final ChatStatus status;
  final List<Message> messages;
  final Failure? failure;

  bool get isSending => status == ChatStatus.sending;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      ChatState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, messages, failure];
}
