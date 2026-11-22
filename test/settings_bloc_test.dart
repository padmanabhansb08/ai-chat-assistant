import 'package:ai_chat_assistant/domain/entities/app_theme_mode.dart';
import 'package:ai_chat_assistant/domain/entities/provider_config.dart';
import 'package:ai_chat_assistant/domain/usecases/settings_usecases.dart';
import 'package:ai_chat_assistant/presentation/blocs/settings/settings_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProviderConfig extends Mock implements GetProviderConfig {}

class MockSaveProviderConfig extends Mock implements SaveProviderConfig {}

class MockGetThemeMode extends Mock implements GetThemeMode {}

class MockSaveThemeMode extends Mock implements SaveThemeMode {}

void main() {
  late MockGetProviderConfig getConfig;
  late MockSaveProviderConfig saveConfig;
  late MockGetThemeMode getTheme;
  late MockSaveThemeMode saveTheme;

  const config = ProviderConfig(
    id: 'default',
    providerName: 'Test',
    type: ProviderType.openAiCompatible,
    baseUrl: 'http://localhost:1234/v1',
    model: 'm',
  );

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
    registerFallbackValue(config);
  });

  setUp(() {
    getConfig = MockGetProviderConfig();
    saveConfig = MockSaveProviderConfig();
    getTheme = MockGetThemeMode();
    saveTheme = MockSaveThemeMode();
    when(() => getConfig()).thenAnswer((_) async => config);
    when(() => getTheme()).thenAnswer((_) async => AppThemeMode.system);
    when(() => saveTheme(any())).thenAnswer((_) async {});
    when(() => saveConfig(any())).thenAnswer((_) async {});
  });

  SettingsBloc build() => SettingsBloc(
        getProviderConfig: getConfig,
        saveProviderConfig: saveConfig,
        getThemeMode: getTheme,
        saveThemeMode: saveTheme,
      );

  blocTest<SettingsBloc, SettingsState>(
    'started loads config and theme',
    build: build,
    act: (b) => b.add(const SettingsStarted()),
    expect: () => [const SettingsLoaded(config)],
  );

  blocTest<SettingsBloc, SettingsState>(
    'theme change persists and keeps config',
    build: build,
    act: (b) async {
      b.add(const SettingsStarted());
      await Future<void>.delayed(Duration.zero);
      b.add(const SettingsThemeChanged(AppThemeMode.dark));
    },
    expect: () => [
      const SettingsLoaded(config),
      const SettingsLoaded(config, themeMode: AppThemeMode.dark),
    ],
    verify: (_) => verify(() => saveTheme(AppThemeMode.dark)).called(1),
  );

  blocTest<SettingsBloc, SettingsState>(
    'save keeps the current theme and flags justSaved',
    build: build,
    seed: () => const SettingsLoaded(config, themeMode: AppThemeMode.dark),
    act: (b) => b.add(const SettingsSaved(config)),
    expect: () => [
      const SettingsLoaded(config, themeMode: AppThemeMode.dark, justSaved: true),
    ],
  );
}
