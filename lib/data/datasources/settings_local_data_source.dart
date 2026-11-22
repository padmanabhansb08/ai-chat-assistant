import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/provider_config.dart';
import '../models/provider_config_model.dart';

/// Non-secret config in SharedPreferences, API key in the platform keystore.
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _configKey = 'provider_config';
  static const _apiKeyKey = 'provider_api_key';

  Future<ProviderConfig?> read() async {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return null;
    final apiKey = await _secure.read(key: _apiKeyKey) ?? '';
    return ProviderConfigModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      apiKey: apiKey,
    );
  }

  static const _themeKey = 'theme_mode';

  AppThemeMode readThemeMode() {
    final name = _prefs.getString(_themeKey);
    return AppThemeMode.values.asNameMap()[name] ?? AppThemeMode.system;
  }

  Future<void> writeThemeMode(AppThemeMode mode) => _prefs.setString(_themeKey, mode.name);

  Future<void> write(ProviderConfig config) async {
    await _prefs.setString(_configKey, jsonEncode(ProviderConfigModel(config).toJson()));
    await _secure.write(key: _apiKeyKey, value: config.apiKey);
  }
}
