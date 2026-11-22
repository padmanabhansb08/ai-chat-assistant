import 'package:equatable/equatable.dart';

/// Wire protocol spoken by a provider.
enum ProviderType { openAiCompatible, gemini }

class ProviderConfig extends Equatable {
  const ProviderConfig({
    required this.id,
    required this.providerName,
    required this.type,
    required this.baseUrl,
    required this.model,
    this.apiKey = '',
  });

  final String id;
  final String providerName;
  final ProviderType type;
  final String baseUrl;
  final String model;
  final String apiKey;

  /// Local servers (e.g. LM Studio) need no key, so only URL + model are required.
  bool get isComplete => baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  ProviderConfig copyWith({
    String? providerName,
    ProviderType? type,
    String? baseUrl,
    String? model,
    String? apiKey,
  }) =>
      ProviderConfig(
        id: id,
        providerName: providerName ?? this.providerName,
        type: type ?? this.type,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        apiKey: apiKey ?? this.apiKey,
      );

  @override
  List<Object?> get props => [id, providerName, type, baseUrl, model, apiKey];
}
