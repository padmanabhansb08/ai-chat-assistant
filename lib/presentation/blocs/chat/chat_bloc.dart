import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/usecases/conversation_usecases.dart';
import '../../../domain/usecases/send_message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// One instance per open conversation.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.conversationId,
    required GetMessages getMessages,
    required SendMessage sendMessage,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    // droppable(): events arriving while a request is in flight are ignored,
    // so duplicate requests are impossible even if the UI misbehaves.
    on<ChatMessageSent>(_onSent, transformer: droppable());
    on<ChatRetried>(_onRetried, transformer: droppable());
  }

  final String conversationId;
  final GetMessages _getMessages;
  final SendMessage _sendMessage;

  static const _uuid = Uuid();

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading, clearFailure: true));
    try {
      final messages = await _getMessages(conversationId);
      emit(state.copyWith(status: ChatStatus.success, messages: messages));
    } on Failure catch (f) {
      emit(state.copyWith(status: ChatStatus.error, failure: f));
    }
  }

  Future<void> _onSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty || state.isSending) return;

    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    emit(state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, userMessage],
      clearFailure: true,
    ));
    await _deliver(userMessage, emit, persistUserMessage: true);
  }

  Future<void> _onRetried(ChatRetried event, Emitter<ChatState> emit) async {
    if (state.status != ChatStatus.error ||
        state.messages.isEmpty ||
        state.messages.last.role != MessageRole.user) {
      return;
    }
    final userMessage = state.messages.last;
    emit(state.copyWith(status: ChatStatus.sending, clearFailure: true));
    await _deliver(userMessage, emit, persistUserMessage: false);
  }

  Future<void> _deliver(
    Message userMessage,
    Emitter<ChatState> emit, {
    required bool persistUserMessage,
  }) async {
    try {
      final reply = await _sendMessage(
        userMessage: userMessage,
        persistUserMessage: persistUserMessage,
      );
      emit(state.copyWith(
        status: ChatStatus.success,
        messages: [...state.messages, reply],
      ));
    } on Failure catch (f) {
      emit(state.copyWith(status: ChatStatus.error, failure: f));
    } catch (_) {
      emit(state.copyWith(status: ChatStatus.error, failure: const UnknownFailure()));
    }
  }
}
