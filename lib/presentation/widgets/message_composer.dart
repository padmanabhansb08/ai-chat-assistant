import 'package:flutter/material.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({required this.onSend, required this.enabled, super.key});

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

// Text controller is purely local UI state; sending goes through ChatBloc.
class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Rebuild only the button as the text changes.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => IconButton.filled(
                onPressed:
                    widget.enabled && value.text.trim().isNotEmpty ? _submit : null,
                icon: const Icon(Icons.send),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
