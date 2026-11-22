import '../entities/app_theme_mode.dart';
import '../entities/provider_config.dart';
import '../repositories/settings_repository.dart';

class GetProviderConfig {
  const GetProviderConfig(this._repository);
  final SettingsRepository _repository;

  Future<ProviderConfig> call() => _repository.getProviderConfig();
}

class SaveProviderConfig {
  const SaveProviderConfig(this._repository);
  final SettingsRepository _repository;

  Future<void> call(ProviderConfig config) => _repository.saveProviderConfig(config);
}

class GetThemeMode {
  const GetThemeMode(this._repository);
  final SettingsRepository _repository;

  Future<AppThemeMode> call() => _repository.getThemeMode();
}

class SaveThemeMode {
  const SaveThemeMode(this._repository);
  final SettingsRepository _repository;

  Future<void> call(AppThemeMode mode) => _repository.saveThemeMode(mode);
}
