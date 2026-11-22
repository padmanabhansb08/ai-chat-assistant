import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'domain/entities/app_theme_mode.dart';
import 'presentation/blocs/conversation/conversation_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/screens/conversations_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const App());
}

AppThemeMode _modeOf(SettingsState s) =>
    s is SettingsLoaded ? s.themeMode : AppThemeMode.system;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ConversationBloc>()..add(const ConversationsRequested()),
        ),
        BlocProvider(create: (_) => getIt<SettingsBloc>()..add(const SettingsStarted())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (prev, curr) => _modeOf(prev) != _modeOf(curr),
        builder: (context, state) => MaterialApp(
          title: 'AI Chat Assistant',
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
          themeMode: switch (_modeOf(state)) {
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.system => ThemeMode.system,
          },
          home: const ConversationsScreen(),
        ),
      ),
    );
  }
}
