import 'package:ai_chat_assistant/core/error/failures.dart';
import 'package:ai_chat_assistant/domain/entities/message.dart';
import 'package:ai_chat_assistant/domain/entities/provider_config.dart';
import 'package:ai_chat_assistant/domain/repositories/ai_repository.dart';
import 'package:ai_chat_assistant/domain/repositories/conversation_repository.dart';
import 'package:ai_chat_assistant/domain/repositories/settings_repository.dart';
import 'package:ai_chat_assistant/domain/usecases/send_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConversations extends Mock implements ConversationRepository {}

class MockAi extends Mock implements AiRepository {}

class MockSettings extends Mock implements SettingsRepository {}

void main() {
  late MockConversations conversations;
  late MockAi ai;
  late MockSettings settings;
  late SendMessage sendMessage;

  const config = ProviderConfig(
    id: 'd',
    providerName: 'T',
    type: ProviderType.openAiCompatible,
    baseUrl: 'http://x/v1',
    model: 'm',
  );

  Message userMsg(String text) => Message(
        id: 'u',
        conversationId: 'c1',
        role: MessageRole.user,
        content: text,
        timestamp: DateTime(2025),
      );

  setUpAll(() {
    registerFallbackValue(userMsg('x'));
    registerFallbackValue(config);
  });

  setUp(() {
    conversations = MockConversations();
    ai = MockAi();
    settings = MockSettings();
    sendMessage = SendMessage(conversations, ai, settings);
    when(() => conversations.addMessage(any())).thenAnswer((_) async {});
    when(() => conversations.renameConversation(any(), any())).thenAnswer((_) async {});
    when(() => settings.getProviderConfig()).thenAnswer((_) async => config);
    when(() => ai.complete(config: any(named: 'config'), history: any(named: 'history')))
        .thenAnswer((_) async => 'answer');
  });

  test('first message becomes the conversation title', () async {
    final first = userMsg('  Explain   Bloc\nplease ');
    when(() => conversations.getMessages('c1')).thenAnswer((_) async => [first]);

    final reply = await sendMessage(userMessage: first);

    expect(reply.content, 'answer');
    expect(reply.role, MessageRole.assistant);
    verify(() => conversations.renameConversation('c1', 'Explain Bloc please')).called(1);
    verify(() => conversations.addMessage(any())).called(2); // user + assistant
  });

  test('later messages do not rename the conversation', () async {
    final m = userMsg('second');
    when(() => conversations.getMessages('c1')).thenAnswer((_) async => [m, m]);

    await sendMessage(userMessage: m);

    verifyNever(() => conversations.renameConversation(any(), any()));
  });

  test('persistUserMessage: false stores only the reply', () async {
    final m = userMsg('again');
    when(() => conversations.getMessages('c1')).thenAnswer((_) async => [m]);

    await sendMessage(userMessage: m, persistUserMessage: false);

    verify(() => conversations.addMessage(any())).called(1);
    verifyNever(() => conversations.renameConversation(any(), any()));
  });

  test('incomplete config -> ConfigFailure, user message still stored', () async {
    final m = userMsg('hi');
    when(() => conversations.getMessages('c1')).thenAnswer((_) async => [m]);
    when(() => settings.getProviderConfig())
        .thenAnswer((_) async => config.copyWith(baseUrl: ''));

    await expectLater(sendMessage(userMessage: m), throwsA(isA<ConfigFailure>()));
    verify(() => conversations.addMessage(m)).called(1);
    verifyNever(() => ai.complete(config: any(named: 'config'), history: any(named: 'history')));
  });

  test('titleFrom truncates long text with an ellipsis', () {
    final t = SendMessage.titleFrom('a' * 100);
    expect(t.length, SendMessage.maxTitleLength);
    expect(t.endsWith('…'), isTrue);
  });
}
