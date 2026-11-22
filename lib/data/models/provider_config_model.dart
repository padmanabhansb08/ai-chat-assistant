import '../../domain/entities/provider_config.dart';

/// Serialises everything except the API key, which lives in secure storage.
class ProviderConfigModel {
  const ProviderConfigModel(this.config);

  final ProviderConfig config;

  static ProviderConfig fromJson(Map<String, dynamic> json, {required String apiKey}) =>
      ProviderConfig(
        id: json['id'] as String,
        providerName: json['providerName'] as String,
        type: ProviderType.values.byName(json['type'] as String),
        baseUrl: json['baseUrl'] as String,
        model: json['model'] as String,
        apiKey: apiKey,
      );

  Map<String, dynamic> toJson() => {
        'id': config.id,
        'providerName': config.providerName,
        'type': config.type.name,
        'baseUrl': config.baseUrl,
        'model': config.model,
      };
}
