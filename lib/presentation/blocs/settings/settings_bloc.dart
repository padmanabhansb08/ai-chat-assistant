import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/app_theme_mode.dart';
import '../../../domain/entities/provider_config.dart';
import '../../../domain/usecases/settings_usecases.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required GetProviderConfig getProviderConfig,
    required SaveProviderConfig saveProviderConfig,
    required GetThemeMode getThemeMode,
    required SaveThemeMode saveThemeMode,
  })  : _getConfig = getProviderConfig,
        _saveConfig = saveProviderConfig,
        _getTheme = getThemeMode,
        _saveTheme = saveThemeMode,
        super(const SettingsLoading()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsSaved>(_onSaved);
    on<SettingsThemeChanged>(_onThemeChanged);
  }

  final GetProviderConfig _getConfig;
  final SaveProviderConfig _saveConfig;
  final GetThemeMode _getTheme;
  final SaveThemeMode _saveTheme;

  AppThemeMode get _currentTheme {
    final s = state;
    return s is SettingsLoaded ? s.themeMode : AppThemeMode.system;
  }

  Future<void> _onStarted(SettingsStarted event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoaded(await _getConfig(), themeMode: await _getTheme()));
    } on Failure catch (f) {
      emit(SettingsError(f));
    }
  }

  Future<void> _onSaved(SettingsSaved event, Emitter<SettingsState> emit) async {
    try {
      await _saveConfig(event.config);
      emit(SettingsLoaded(event.config, themeMode: _currentTheme, justSaved: true));
    } on Failure catch (f) {
      emit(SettingsError(f));
    }
  }

  Future<void> _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    try {
      await _saveTheme(event.mode);
      emit(SettingsLoaded(current.config, themeMode: event.mode));
    } on Failure catch (f) {
      emit(SettingsError(f));
    }
  }
}
