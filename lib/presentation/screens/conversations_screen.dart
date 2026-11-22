import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/conversation/conversation_bloc.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConversationBloc, ConversationState>(
      // Navigate only when a conversation becomes the opened one.
      listenWhen: (prev, curr) =>
          curr is ConversationLoaded &&
          curr.openedId != null &&
          !(prev is ConversationLoaded && prev.openedId == curr.openedId),
      listener: (context, state) async {
        final loaded = state as ConversationLoaded;
        final conversation =
            loaded.conversations.firstWhere((c) => c.id == loaded.openedId);
        final bloc = context.read<ConversationBloc>();
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            title: conversation.title,
          ),
        ));
        bloc
          ..add(const ConversationClosed())
          ..add(const ConversationsRequested());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'AI provider settings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.read<ConversationBloc>().add(
                ConversationCreated(
                  'Chat ${DateFormat.MMMd().add_jm().format(DateTime.now())}',
                ),
              ),
          icon: const Icon(Icons.add),
          label: const Text('New chat'),
        ),
        body: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) => switch (state) {
            ConversationLoading() => const Center(child: CircularProgressIndicator()),
            ConversationEmpty() => const Center(
                child: Text('No conversations yet.\nTap "New chat" to start.',
                    textAlign: TextAlign.center),
              ),
            ConversationError(:final failure) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context
                          .read<ConversationBloc>()
                          .add(const ConversationsRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ConversationLoaded(:final conversations) => ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = conversations[i];
                  return Dismissible(
                    key: ValueKey(c.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) =>
                        context.read<ConversationBloc>().add(ConversationDeleted(c.id)),
                    child: ListTile(
                      title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          'Updated ${DateFormat.yMMMd().add_jm().format(c.updatedAt)}'),
                      onTap: () =>
                          context.read<ConversationBloc>().add(ConversationOpened(c.id)),
                    ),
                  );
                },
              ),
          },
        ),
      ),
    );
  }
}
