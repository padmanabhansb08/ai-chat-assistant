import '../../core/error/failures.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/entities/provider_preset.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  static const _defaultId = 'default';

  @override
  Future<ProviderConfig> getProviderConfig() async {
    try {
      final stored = await _local.read();
      if (stored != null) return stored;
    } catch (_) {
      throw const StorageFailure();
    }
    final preset = ProviderPreset.all.first;
    return ProviderConfig(
      id: _defaultId,
      providerName: preset.name,
      type: preset.type,
      baseUrl: preset.baseUrl,
      model: preset.model,
    );
  }

  @override
  Future<AppThemeMode> getThemeMode() async {
    try {
      return _local.readThemeMode();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      await _local.writeThemeMode(mode);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> saveProviderConfig(ProviderConfig config) async {
    try {
      await _local.write(config);
    } catch (_) {
      throw const StorageFailure();
    }
  }
}
