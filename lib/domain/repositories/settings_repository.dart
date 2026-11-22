import '../entities/app_theme_mode.dart';
import '../entities/provider_config.dart';

abstract interface class SettingsRepository {
  Future<ProviderConfig> getProviderConfig();
  Future<void> saveProviderConfig(ProviderConfig config);

  Future<AppThemeMode> getThemeMode();
  Future<void> saveThemeMode(AppThemeMode mode);
}
