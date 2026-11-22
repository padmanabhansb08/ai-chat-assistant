# AI Chat Assistant

A Flutter chat app that talks to configurable AI providers (OpenAI, Gemini, or any
OpenAI-compatible endpoint such as OpenRouter or LM Studio). State is managed with
`flutter_bloc`; conversations are stored locally in SQLite.

## Setup

1. Install Flutter (stable channel; built and tested with Flutter 3.50 / Dart 3.14).
2. `flutter pub get`
3. Start an Android emulator or connect a device, then `flutter run`.
4. Open **Settings** in the app, pick a preset, enter your API key and model, tap **Save**.
5. Optional: `flutter test` and `flutter analyze`.

Android needs a JDK 17 and the Android SDK (platform 36). The `android/` and `ios/`
folders are included.

### Local servers (LM Studio)
- Android emulator: use `http://10.0.2.2:1234/v1` (not `localhost`).
- Debug builds already allow plain `http://` (see `android/app/src/debug/AndroidManifest.xml`);
  release builds do not. iOS would need an ATS exception.

## Environment variables
None. There are no build-time secrets: the base URL, model and API key are entered
in the app and stored on-device (key in the platform keystore). Never commit keys.

## Features
- Create, list, open and delete conversations (swipe to delete)
- Chat with timestamps, multiline composer, typing indicator, no empty or duplicate sends
- Configurable provider: name, base URL, API key, model (persisted)
- OpenAI-compatible and Gemini protocols behind one interface
- Typed error handling: network, timeout, auth, rate limit, invalid response; shown in an inline banner with a **Retry** button (re-sends without duplicating the stored message)
- Conversations are auto-titled from the first message
- Fully offline browsing of stored chats
- **Bonus: Markdown rendering** of AI replies (headings, lists, code blocks, inline formatting) via `flutter_markdown_plus`; user messages stay plain text
- **Bonus: Dark mode** — System / Light / Dark, chosen in Settings, persisted in `shared_preferences` and driven by `SettingsBloc` (`SettingsThemeChanged`)

## Architecture
```
presentation (screens, widgets, blocs)  ->  domain (entities, repository interfaces, usecases)
                                                  ^
data (datasources, models, repository impls) -----+
```
- `domain` has no Flutter or package-IO dependencies beyond `equatable`/`uuid`.
- `data` implements the domain repository interfaces; models map to/from SQLite rows / JSON.
- Dependencies are wired in `core/di/injection.dart` (get_it). Widgets only see Blocs.
- Data layer throws typed `Failure`s (`core/error/failures.dart`); Blocs catch them
  and put them in state; UI shows `failure.message`.

## Bloc architecture overview
| Bloc | Events | States |
|---|---|---|
| `ConversationBloc` | `ConversationsRequested`, `ConversationCreated`, `ConversationOpened`, `ConversationClosed`, `ConversationDeleted` | `ConversationLoading`, `ConversationEmpty`, `ConversationLoaded(conversations, openedId)`, `ConversationError` |
| `ChatBloc` (one per open chat) | `ChatStarted`, `ChatMessageSent`, `ChatRetried` | single `ChatState{status, messages, failure}`; `ChatStatus` = initial / loading / sending / success / error |
| `SettingsBloc` | `SettingsStarted`, `SettingsSaved`, `SettingsThemeChanged` | `SettingsLoading`, `SettingsLoaded(config, themeMode, justSaved)`, `SettingsError` |

Design decisions:
- `ChatState` is one class with a status enum (instead of separate subclasses) so the
  message list stays on screen during loading and errors.
- `ChatMessageSent` uses `droppable()`: duplicate requests are blocked in the Bloc,
  not only by disabling the button.
- `ConversationBloc` serialises writes with `sequential()`.
- The user message is persisted before the network call, so it survives failures.

## Local storage design
SQLite (`sqflite`), file `chat.db`:
- `conversations(id, title, created_at, updated_at)`
- `messages(id, conversation_id -> conversations ON DELETE CASCADE, role, content, timestamp)`
  with an index on `(conversation_id, timestamp)`.

Provider config: non-secret fields as JSON in `shared_preferences`; API key in
`flutter_secure_storage`.

## Tests
`flutter test` — 26 tests: `ChatBloc` (send, failure, retry, duplicate-drop), `SettingsBloc`
(theme), the `SendMessage` usecase (auto-title, no double-store, config check), and the
remote data sources with a fake HTTP client (401/403, 429, 5xx, socket error, timeout,
invalid body, OpenAI request shape, Gemini request/response shape).

## Known limitations
- Verified on an Android emulator against a local mock OpenAI-compatible server and unit
  tests; not run against live OpenAI, Gemini or OpenRouter.
- iOS was not built or run.
- The chat screen's app-bar title updates to the auto-title when you return to the list.
