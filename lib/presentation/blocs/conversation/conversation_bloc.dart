import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/usecases/conversation_usecases.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc({
    required GetConversations getConversations,
    required CreateConversation createConversation,
    required DeleteConversation deleteConversation,
  })  : _getConversations = getConversations,
        _createConversation = createConversation,
        _deleteConversation = deleteConversation,
        super(const ConversationLoading()) {
    // sequential(): writes and reloads never interleave.
    on<ConversationsRequested>(_onRequested, transformer: sequential());
    on<ConversationCreated>(_onCreated, transformer: sequential());
    on<ConversationDeleted>(_onDeleted, transformer: sequential());
    on<ConversationOpened>(_onOpened);
    on<ConversationClosed>(_onClosed);
  }

  final GetConversations _getConversations;
  final CreateConversation _createConversation;
  final DeleteConversation _deleteConversation;

  Future<void> _onRequested(
    ConversationsRequested event,
    Emitter<ConversationState> emit,
  ) async {
    if (state is! ConversationLoaded) emit(const ConversationLoading());
    await _reload(emit);
  }

  Future<void> _onCreated(
    ConversationCreated event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final created = await _createConversation(event.title);
      await _reload(emit, openedId: created.id);
    } on Failure catch (f) {
      emit(ConversationError(f));
    }
  }

  Future<void> _onDeleted(
    ConversationDeleted event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _deleteConversation(event.id);
      await _reload(emit);
    } on Failure catch (f) {
      emit(ConversationError(f));
    }
  }

  void _onOpened(ConversationOpened event, Emitter<ConversationState> emit) {
    final current = state;
    if (current is ConversationLoaded) {
      emit(ConversationLoaded(current.conversations, openedId: event.id));
    }
  }

  void _onClosed(ConversationClosed event, Emitter<ConversationState> emit) {
    final current = state;
    if (current is ConversationLoaded && current.openedId != null) {
      emit(ConversationLoaded(current.conversations));
    }
  }

  Future<void> _reload(Emitter<ConversationState> emit, {String? openedId}) async {
    try {
      final list = await _getConversations();
      emit(list.isEmpty
          ? const ConversationEmpty()
          : ConversationLoaded(list, openedId: openedId));
    } on Failure catch (f) {
      emit(ConversationError(f));
    }
  }
}
