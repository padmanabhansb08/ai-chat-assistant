# AI Usage Report

This project was built almost entirely with an AI coding agent. This report states
that plainly and lists what the AI did, what I did, and the decisions behind the code.

## 1. AI tools used

| Tool | How it was used |
|---|---|
| **Claude Code** (Claude Sonnet 5.5, desktop app) | Analysed the assessment PDF, designed the architecture, wrote all source and test code, installed the toolchain (Flutter, Android SDK, JDK), ran the app on an Android emulator, debugged, wrote the documentation, and created the Git repository. |

No other AI tools (ChatGPT, Copilot, Cursor, etc.) were used.

## 2. Prompts used

My prompts to the agent, in order (verbatim):

1. "analyse this" (with the assessment PDF attached)
2. "Yes, scaffold it"
3. "Install Flutter"
4. "Yes, run it"
5. "Yes, test it"
6. "Add bonus features"
7. "Fix UI polish"
8. "ok fix all"
9. "itzs ok make the process complete so that i can subit"
10. "create repo and push it"
11. "ok fill the ai_usage.md and submit by email"

Choices I made when the agent asked: install the Android SDK and create an emulator
(rather than use a phone), make the GitHub repository public, and authorise the
GitHub CLI login in my browser.

## 3. Generated code (by AI)

All application code, tests and documentation, including:

- **Architecture and layering:** `lib/core/`, `lib/domain/`, `lib/data/`, `lib/presentation/`, `lib/main.dart`
- **Blocs:** `ConversationBloc`, `ChatBloc`, `SettingsBloc` with their events and states
- **Data layer:** SQLite schema and data sources, secure storage of the API key, OpenAI-compatible and Gemini remote data sources, repository implementations
- **UI:** conversation list, chat screen, settings screen, message bubble, composer, typing indicator, error banner with Retry
- **Bonus features:** markdown rendering of AI replies; persisted light/dark/system theme
- **Tests (26):** `chat_bloc_test.dart`, `chat_retry_test.dart`, `settings_bloc_test.dart`, `send_message_test.dart`, `remote_data_source_test.dart`
- **Config and docs:** `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, Android manifest changes, `README.md`, this file

Also generated but **not committed**: a small Python mock OpenAI-compatible server
used only to test the app on the emulator (delayed replies, a 429 response, markdown replies).

## 4. Manually written code

**None.** I did not hand-write or hand-edit any source file. My contribution was
directing the work: choosing the project, approving each step, choosing the
Android emulator route and a public repository, approving the GitHub login, and
reviewing the results shown on the emulator.

I am aware this means I must be able to explain the generated code in an interview.
The parts I should be able to walk through are listed under "Engineering decisions".

## 5. Verification performed

- `flutter analyze`: no errors (7 info-level notices about Flutter 3.50 deprecating `package:flutter/material.dart`).
- `flutter test`: 26 tests pass.
- Ran on an Android emulator (Android 35) against the mock server: created a chat, sent messages, received replies, markdown rendering, restart persistence, swipe-to-delete, theme persistence, typing indicator, rate-limit (429) error with Retry, network-failure error, auto-title.
- Built a release APK successfully.

**Not verified:** calls to the real OpenAI, Gemini or OpenRouter services (no API key was used in testing; the Gemini request and response shapes are covered by unit tests with a fake HTTP client only). iOS was not built or run.

## 6. Engineering decisions

- **Layering:** presentation / domain / data, as the brief's structure requires. Blocs depend on use cases, never on data sources or UI; dependencies are wired in one place (`core/di/injection.dart`, get_it).
- **Typed failures:** the data layer throws `Failure` subclasses (network, timeout, auth, rate limit, invalid response, server, config, storage). HTTP status codes are mapped in a single function (`core/network/http_guard.dart`). Blocs catch `Failure` and put it in state.
- **Provider-agnostic AI:** an `AiRemoteDataSource` interface with two implementations (OpenAI-compatible `/chat/completions`, and Gemini `generateContent`), selected by `ProviderType`. Base URL, API key and model are user-configured and persisted; nothing is hardcoded. Presets only pre-fill the form.
- **Secrets:** the API key is stored with `flutter_secure_storage`, not in SQLite or SharedPreferences. Gemini uses an `x-goog-api-key` header so the key never appears in a URL. No secrets are in the repository.
- **SQLite over Hive:** messages belong to conversations, so a relational schema with `ON DELETE CASCADE` and an index on `(conversation_id, timestamp)` fits; the message insert and the conversation `updated_at` bump run in one transaction.
- **`ChatState` as one class with a status enum** (initial / loading / sending / success / error) instead of separate subclasses, so the message list stays on screen during loading and errors. `ConversationBloc` and `SettingsBloc` use sealed state subclasses as in the brief.
- **Duplicate-request protection in the Bloc:** `droppable()` on `ChatMessageSent` plus an `isSending` guard, so repeated requests are ignored even if the UI misbehaves. `ConversationBloc` uses `sequential()` for writes.
- **User message saved before the network call**, so it survives failures and offline use. **Retry** (`ChatRetried`) re-sends it with `persistUserMessage: false`, so history is never duplicated.
- **Conversation opening owned by the Bloc:** `ConversationOpened` / `ConversationClosed` events with `openedId` in `ConversationLoaded`; the screen only reacts to state.
- **Theme preference through `SettingsBloc`** (`SettingsThemeChanged`) with a UI-framework-free `AppThemeMode` enum in the domain layer.
- **Cleartext HTTP only in the debug manifest** (for local servers such as LM Studio); release builds block it. `INTERNET` permission is in the main manifest.
- **Bonus features chosen:** markdown rendering and dark mode (persisted).
- **Known limitation:** the chat screen's app-bar title shows the original timestamp title until you return to the list, where the auto-title appears.
