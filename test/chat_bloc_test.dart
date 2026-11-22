import 'package:ai_chat_assistant/core/error/failures.dart';
import 'package:ai_chat_assistant/domain/entities/message.dart';
import 'package:ai_chat_assistant/domain/usecases/conversation_usecases.dart';
import 'package:ai_chat_assistant/domain/usecases/send_message.dart';
import 'package:ai_chat_assistant/presentation/blocs/chat/chat_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMessages extends Mock implements GetMessages {}

class MockSendMessage extends Mock implements SendMessage {}

void main() {
  late MockGetMessages getMessages;
  late MockSendMessage sendMessage;

  final reply = Message(
    id: 'r1',
    conversationId: 'c1',
    role: MessageRole.assistant,
    content: 'hi there',
    timestamp: DateTime(2025),
  );

  setUpAll(() {
    registerFallbackValue(reply);
  });

  setUp(() {
    getMessages = MockGetMessages();
    sendMessage = MockSendMessage();
  });

  ChatBloc build() => ChatBloc(
        conversationId: 'c1',
        getMessages: getMessages,
        sendMessage: sendMessage,
      );

  blocTest<ChatBloc, ChatState>(
    'ignores empty messages',
    build: build,
    act: (b) => b.add(const ChatMessageSent('   ')),
    expect: () => <ChatState>[],
    verify: (_) => verifyNever(() => sendMessage(
            userMessage: any(named: 'userMessage'),
            persistUserMessage: any(named: 'persistUserMessage'))),
  );

  blocTest<ChatBloc, ChatState>(
    'sending -> success appends user message and reply',
    build: () {
      when(() => sendMessage(
            userMessage: any(named: 'userMessage'),
            persistUserMessage: any(named: 'persistUserMessage')))
          .thenAnswer((_) async => reply);
      return build();
    },
    act: (b) => b.add(const ChatMessageSent('hello')),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.sending),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.success)
          .having((s) => s.messages.length, 'messages', 2),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'failure keeps the messages and exposes the failure',
    build: () {
      when(() => sendMessage(
            userMessage: any(named: 'userMessage'),
            persistUserMessage: any(named: 'persistUserMessage')))
          .thenThrow(const AuthFailure());
      return build();
    },
    act: (b) => b.add(const ChatMessageSent('hello')),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.sending),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.error)
          .having((s) => s.failure, 'failure', const AuthFailure())
          .having((s) => s.messages.length, 'messages', 1),
    ],
  );
}
