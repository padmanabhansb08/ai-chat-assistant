import 'package:http/http.dart' as http;

import '../../core/error/failures.dart';
import '../../core/network/http_guard.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/provider_config.dart';
import 'ai_remote_data_source.dart';

/// Google Gemini `generateContent` API (different shape from OpenAI).
class GeminiDataSource implements AiRemoteDataSource {
  GeminiDataSource(this._client);

  final http.Client _client;

  @override
  Future<String> complete({
    required ProviderConfig config,
    required List<Message> history,
  }) async {
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$base/models/${config.model}:generateContent');
    if (uri == null || !uri.hasScheme) throw const ConfigFailure('Invalid base URL.');

    final response = await guardedPost(
      _client,
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Header instead of ?key= so the key never lands in URLs or logs.
        'x-goog-api-key': config.apiKey,
      },
      body: {
        'contents': [
          for (final m in history.where((m) => m.role != MessageRole.system))
            {
              'role': m.role == MessageRole.assistant ? 'model' : 'user',
              'parts': [
                {'text': m.content},
              ],
            },
        ],
      },
    );

    final json = decodeJsonObject(response.body);
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = (candidates.first as Map<String, dynamic>)['content'];
      final parts = content is Map<String, dynamic> ? content['parts'] : null;
      if (parts is List && parts.isNotEmpty) {
        final text = (parts.first as Map<String, dynamic>)['text'];
        if (text is String && text.isNotEmpty) return text;
      }
    }
    throw const InvalidResponseFailure();
  }
}
