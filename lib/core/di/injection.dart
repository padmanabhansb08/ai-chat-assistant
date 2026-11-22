import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/ai_remote_data_source.dart';
import '../../data/datasources/app_database.dart';
import '../../data/datasources/conversation_local_data_source.dart';
import '../../data/datasources/gemini_data_source.dart';
import '../../data/datasources/openai_compatible_data_source.dart';
import '../../data/datasources/settings_local_data_source.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/conversation_usecases.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/conversation/conversation_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  // External
  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage())
    ..registerSingleton<http.Client>(http.Client())
    ..registerSingleton<AppDatabase>(AppDatabase());

  // Data sources
  getIt
    ..registerLazySingleton(() => ConversationLocalDataSource(getIt()))
    ..registerLazySingleton(() => SettingsLocalDataSource(getIt(), getIt()));

  // Repositories
  getIt
    ..registerLazySingleton<ConversationRepository>(
      () => ConversationRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt()))
    ..registerLazySingleton<AiRepository>(
      () => AiRepositoryImpl(
        sources: <ProviderType, AiRemoteDataSource>{
          ProviderType.openAiCompatible: OpenAiCompatibleDataSource(getIt()),
          ProviderType.gemini: GeminiDataSource(getIt()),
        },
      ),
    );

  // Use cases
  getIt
    ..registerFactory(() => GetConversations(getIt()))
    ..registerFactory(() => CreateConversation(getIt()))
    ..registerFactory(() => DeleteConversation(getIt()))
    ..registerFactory(() => GetMessages(getIt()))
    ..registerFactory(() => SendMessage(getIt(), getIt(), getIt()))
    ..registerFactory(() => GetProviderConfig(getIt()))
    ..registerFactory(() => SaveProviderConfig(getIt()))
    ..registerFactory(() => GetThemeMode(getIt()))
    ..registerFactory(() => SaveThemeMode(getIt()));

  // Blocs (factories: the widget tree owns and closes them)
  getIt
    ..registerFactory(
      () => ConversationBloc(
        getConversations: getIt(),
        createConversation: getIt(),
        deleteConversation: getIt(),
      ),
    )
    ..registerFactory(
      () => SettingsBloc(
        getProviderConfig: getIt(),
        saveProviderConfig: getIt(),
        getThemeMode: getIt(),
        saveThemeMode: getIt(),
      ),
    )
    ..registerFactoryParam<ChatBloc, String, void>(
      (conversationId, _) => ChatBloc(
        conversationId: conversationId,
        getMessages: getIt(),
        sendMessage: getIt(),
      ),
    );
}
