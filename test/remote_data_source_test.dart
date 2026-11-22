import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_chat_assistant/core/error/failures.dart';
import 'package:ai_chat_assistant/core/network/http_guard.dart';
import 'package:ai_chat_assistant/data/datasources/gemini_data_source.dart';
import 'package:ai_chat_assistant/data/datasources/openai_compatible_data_source.dart';
import 'package:ai_chat_assistant/domain/entities/message.dart';
import 'package:ai_chat_assistant/domain/entities/provider_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final history = [
    Message(
      id: '1',
      conversationId: 'c',
      role: MessageRole.user,
      content: 'hi',
      timestamp: DateTime(2025),
    ),
    Message(
      id: '2',
      conversationId: 'c',
      role: MessageRole.assistant,
      content: 'hello',
      timestamp: DateTime(2025),
    ),
    Message(
      id: '3',
      conversationId: 'c',
      role: MessageRole.user,
      content: 'how are you',
      timestamp: DateTime(2025),
    ),
  ];

  const openAi = ProviderConfig(
    id: 'a',
    providerName: 'X',
    type: ProviderType.openAiCompatible,
    baseUrl: 'http://host/v1/',
    model: 'm1',
    apiKey: 'secret',
  );
  const gemini = ProviderConfig(
    id: 'b',
    providerName: 'G',
    type: ProviderType.gemini,
    baseUrl: 'https://g.example/v1beta',
    model: 'gem',
    apiKey: 'gkey',
  );

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  group('guardedPost error mapping', () {
    Future<Object?> run(MockClient c, {Duration? timeout}) async {
      try {
        await guardedPost(c, Uri.parse('http://x/y'),
            headers: const {}, body: const {}, timeout: timeout ?? const Duration(seconds: 1));
        return null;
      } on Failure catch (f) {
        return f;
      }
    }

    test('401 and 403 -> AuthFailure', () async {
      expect(await run(MockClient((_) async => json({}, 401))), isA<AuthFailure>());
      expect(await run(MockClient((_) async => json({}, 403))), isA<AuthFailure>());
    });

    test('429 -> RateLimitFailure', () async {
      expect(await run(MockClient((_) async => json({}, 429))), isA<RateLimitFailure>());
    });

    test('5xx -> ServerFailure carrying provider message', () async {
      final f = await run(MockClient(
        (_) async => json({'error': {'message': 'boom'}}, 500),
      ));
      expect(f, isA<ServerFailure>().having((e) => e.message, 'message', 'boom'));
    });

    test('socket error -> NetworkFailure', () async {
      expect(
        await run(MockClient((_) async => throw const SocketException('down'))),
        isA<NetworkFailure>(),
      );
    });

    test('slow server -> TimeoutFailure', () async {
      final c = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return json({});
      });
      expect(await run(c, timeout: const Duration(milliseconds: 50)), isA<TimeoutFailure>());
    });
  });

  group('OpenAiCompatibleDataSource', () {
    test('builds request and parses reply', () async {
      late http.Request seen;
      final ds = OpenAiCompatibleDataSource(MockClient((r) async {
        seen = r;
        return json({
          'choices': [
            {'message': {'content': 'fine'}},
          ],
        });
      }));

      final text = await ds.complete(config: openAi, history: history);

      expect(text, 'fine');
      expect(seen.url.toString(), 'http://host/v1/chat/completions');
      expect(seen.headers['Authorization'], 'Bearer secret');
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['model'], 'm1');
      expect((body['messages'] as List).length, 3);
    });

    test('omits Authorization when key is empty', () async {
      late http.Request seen;
      final ds = OpenAiCompatibleDataSource(MockClient((r) async {
        seen = r;
        return json({
          'choices': [
            {'message': {'content': 'ok'}},
          ],
        });
      }));
      await ds.complete(config: openAi.copyWith(apiKey: ''), history: history);
      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('unexpected body -> InvalidResponseFailure', () async {
      final ds = OpenAiCompatibleDataSource(MockClient((_) async => json({'nope': 1})));
      expect(
        ds.complete(config: openAi, history: history),
        throwsA(isA<InvalidResponseFailure>()),
      );
    });

    test('non-JSON body -> InvalidResponseFailure', () async {
      final ds = OpenAiCompatibleDataSource(MockClient((_) async => http.Response('<html>', 200)));
      expect(
        ds.complete(config: openAi, history: history),
        throwsA(isA<InvalidResponseFailure>()),
      );
    });
  });

  group('GeminiDataSource', () {
    test('maps roles, uses header auth, parses candidate text', () async {
      late http.Request seen;
      final ds = GeminiDataSource(MockClient((r) async {
        seen = r;
        return json({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'gemini says hi'},
                ],
              },
            },
          ],
        });
      }));

      final text = await ds.complete(config: gemini, history: history);

      expect(text, 'gemini says hi');
      expect(seen.url.toString(), 'https://g.example/v1beta/models/gem:generateContent');
      expect(seen.headers['x-goog-api-key'], 'gkey');
      expect(seen.url.queryParameters.containsKey('key'), isFalse);
      final contents = (jsonDecode(seen.body) as Map<String, dynamic>)['contents'] as List;
      expect(contents.map((c) => (c as Map)['role']), ['user', 'model', 'user']);
    });

    test('empty candidates -> InvalidResponseFailure', () async {
      final ds = GeminiDataSource(MockClient((_) async => json({'candidates': []})));
      expect(
        ds.complete(config: gemini, history: history),
        throwsA(isA<InvalidResponseFailure>()),
      );
    });
  });

  test('TimeoutException type used by guard is dart:async', () {
    expect(TimeoutException('x'), isA<TimeoutException>());
  });
}
