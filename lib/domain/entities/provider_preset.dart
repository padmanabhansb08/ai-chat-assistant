import 'provider_config.dart';

/// Suggested starting values. These are UI conveniences only; the user can
/// edit every field and nothing here is used unless the user saves it.
class ProviderPreset {
  const ProviderPreset(this.name, this.type, this.baseUrl, this.model);

  final String name;
  final ProviderType type;
  final String baseUrl;
  final String model;

  static const all = <ProviderPreset>[
    ProviderPreset('OpenAI', ProviderType.openAiCompatible,
        'https://api.openai.com/v1', 'gpt-4o-mini'),
    ProviderPreset('Gemini', ProviderType.gemini,
        'https://generativelanguage.googleapis.com/v1beta', 'gemini-2.0-flash'),
    ProviderPreset('OpenRouter', ProviderType.openAiCompatible,
        'https://openrouter.ai/api/v1', 'openai/gpt-4o-mini'),
    // Android emulator reaches the host machine at 10.0.2.2, not localhost.
    ProviderPreset('LM Studio', ProviderType.openAiCompatible,
        'http://localhost:1234/v1', 'local-model'),
    ProviderPreset('Custom', ProviderType.openAiCompatible, '', ''),
  ];
}
