import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/provider_config.dart';
import '../../domain/entities/provider_preset.dart';
import '../blocs/settings/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI provider')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (_, curr) =>
            (curr is SettingsLoaded && curr.justSaved) || curr is SettingsError,
        listener: (context, state) {
          final text = state is SettingsError ? state.failure.message : 'Settings saved';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) => switch (state) {
          SettingsLoading() => const Center(child: CircularProgressIndicator()),
          SettingsError() => Center(
              child: FilledButton(
                onPressed: () => context.read<SettingsBloc>().add(const SettingsStarted()),
                child: const Text('Retry'),
              ),
            ),
          SettingsLoaded(:final config, :final themeMode) =>
            _SettingsForm(config: config, themeMode: themeMode),
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.config, required this.themeMode});

  final ProviderConfig config;
  final AppThemeMode themeMode;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

// Controllers are ephemeral widget state; persistence goes through SettingsBloc.
class _SettingsFormState extends State<_SettingsForm> {
  late final _name = TextEditingController(text: widget.config.providerName);
  late final _baseUrl = TextEditingController(text: widget.config.baseUrl);
  late final _model = TextEditingController(text: widget.config.model);
  late final _apiKey = TextEditingController(text: widget.config.apiKey);
  late ProviderType _type = widget.config.type;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _applyPreset(ProviderPreset p) => setState(() {
        _name.text = p.name;
        _baseUrl.text = p.baseUrl;
        _model.text = p.model;
        _type = p.type;
      });

  void _save() {
    context.read<SettingsBloc>().add(SettingsSaved(widget.config.copyWith(
          providerName: _name.text.trim(),
          type: _type,
          baseUrl: _baseUrl.text.trim(),
          model: _model.text.trim(),
          apiKey: _apiKey.text.trim(),
        )));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(value: AppThemeMode.system, label: Text('System')),
            ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
            ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
          ],
          selected: {widget.themeMode},
          onSelectionChanged: (s) =>
              context.read<SettingsBloc>().add(SettingsThemeChanged(s.first)),
        ),
        const SizedBox(height: 24),
        Text('AI provider', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final p in ProviderPreset.all)
              ActionChip(label: Text(p.name), onPressed: () => _applyPreset(p)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Provider name'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ProviderType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'API format'),
          items: const [
            DropdownMenuItem(
                value: ProviderType.openAiCompatible, child: Text('OpenAI-compatible')),
            DropdownMenuItem(value: ProviderType.gemini, child: Text('Gemini')),
          ],
          onChanged: (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseUrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'API base URL'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKey,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'API key',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _model,
          decoration: const InputDecoration(labelText: 'Model name'),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
