part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded(
    this.config, {
    this.themeMode = AppThemeMode.system,
    this.justSaved = false,
  });

  final ProviderConfig config;
  final AppThemeMode themeMode;

  /// True only for the state emitted right after a successful save.
  final bool justSaved;

  @override
  List<Object?> get props => [config, themeMode, justSaved];
}

class SettingsError extends SettingsState {
  const SettingsError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
