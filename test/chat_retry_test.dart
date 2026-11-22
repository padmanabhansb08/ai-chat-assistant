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
  final userMsg = Message(
    id: 'u1',
    conversationId: 'c1',
    role: MessageRole.user,
    content: 'hello',
    timestamp: DateTime(2025),
  );
  final reply = Message(
    id: 'r1',
    conversationId: 'c1',
    role: MessageRole.assistant,
    content: 'hi',
    timestamp: DateTime(2025),
  );

  late MockGetMessages getMessages;
  late MockSendMessage sendMessage;

  setUpAll(() => registerFallbackValue(userMsg));
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
    'retry re-sends the last user message without persisting it again',
    build: () {
      when(() => sendMessage(
            userMessage: any(named: 'userMessage'),
            persistUserMessage: false,
          )).thenAnswer((_) async => reply);
      return build();
    },
    seed: () => ChatState(
      status: ChatStatus.error,
      messages: [userMsg],
      failure: const NetworkFailure(),
    ),
    act: (b) => b.add(const ChatRetried()),
    expect: () => [
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.sending)
          .having((s) => s.failure, 'failure', isNull),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.success)
          .having((s) => s.messages, 'messages', [userMsg, reply]),
    ],
    verify: (_) => verify(() => sendMessage(
          userMessage: userMsg,
          persistUserMessage: false,
        )).called(1),
  );

  blocTest<ChatBloc, ChatState>(
    'retry is ignored when there is no failed user message',
    build: build,
    seed: () => ChatState(status: ChatStatus.success, messages: [userMsg, reply]),
    act: (b) => b.add(const ChatRetried()),
    expect: () => <ChatState>[],
  );

  blocTest<ChatBloc, ChatState>(
    'a second send while one is in flight is dropped',
    build: () {
      when(() => sendMessage(
            userMessage: any(named: 'userMessage'),
            persistUserMessage: any(named: 'persistUserMessage'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return reply;
      });
      return build();
    },
    act: (b) {
      b
        ..add(const ChatMessageSent('one'))
        ..add(const ChatMessageSent('two'));
    },
    wait: const Duration(milliseconds: 150),
    verify: (_) => verify(() => sendMessage(
          userMessage: any(named: 'userMessage'),
          persistUserMessage: any(named: 'persistUserMessage'),
        )).called(1),
  );
}
