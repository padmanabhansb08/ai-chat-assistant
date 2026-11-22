import '../entities/message.dart';
import '../entities/provider_config.dart';

abstract interface class AiRepository {
  /// Returns the assistant's reply text. Throws a `Failure` on error.
  Future<String> complete({
    required ProviderConfig config,
    required List<Message> history,
  });
}
