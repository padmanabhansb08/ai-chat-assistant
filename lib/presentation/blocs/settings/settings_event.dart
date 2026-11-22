part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class SettingsSaved extends SettingsEvent {
  const SettingsSaved(this.config);
  final ProviderConfig config;

  @override
  List<Object?> get props => [config];
}

class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.mode);
  final AppThemeMode mode;

  @override
  List<Object?> get props => [mode];
}
