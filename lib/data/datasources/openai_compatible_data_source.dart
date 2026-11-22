import 'package:http/http.dart' as http;

import '../../core/error/failures.dart';
import '../../core/network/http_guard.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/provider_config.dart';
import 'ai_remote_data_source.dart';

/// Works with OpenAI, OpenRouter, LM Studio and any `/chat/completions` server.
class OpenAiCompatibleDataSource implements AiRemoteDataSource {
  OpenAiCompatibleDataSource(this._client);

  final http.Client _client;

  @override
  Future<String> complete({
    required ProviderConfig config,
    required List<Message> history,
  }) async {
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$base/chat/completions');
    if (uri == null || !uri.hasScheme) throw const ConfigFailure('Invalid base URL.');

    final response = await guardedPost(
      _client,
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
      },
      body: {
        'model': config.model,
        'messages': [
          for (final m in history) {'role': m.role.name, 'content': m.content},
        ],
      },
    );

    final json = decodeJsonObject(response.body);
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = (choices.first as Map<String, dynamic>)['message'];
      final content = message is Map<String, dynamic> ? message['content'] : null;
      if (content is String && content.isNotEmpty) return content;
    }
    throw const InvalidResponseFailure();
  }
}
