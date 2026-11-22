import '../../domain/entities/message.dart';
import '../../domain/entities/provider_config.dart';

/// One implementation per wire protocol.
abstract interface class AiRemoteDataSource {
  Future<String> complete({
    required ProviderConfig config,
    required List<Message> history,
  });
}
