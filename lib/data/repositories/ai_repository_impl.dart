import '../../domain/entities/message.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_data_source.dart';

/// Routes a request to the data source matching the provider's protocol.
class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl({required Map<ProviderType, AiRemoteDataSource> sources})
      : _sources = sources;

  final Map<ProviderType, AiRemoteDataSource> _sources;

  @override
  Future<String> complete({
    required ProviderConfig config,
    required List<Message> history,
  }) =>
      _sources[config.type]!.complete(config: config, history: history);
}
