import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/features/chat/domain/message_validators.dart';
import 'package:spotted/features/chat/presentation/providers/chat_messages_feed.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Campo per scrivere un messaggio nella chat, con il pulsante Invia.
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (!MessageValidators.isValid(text) || _sending) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(chatMessagesFeedProvider(widget.chatId).notifier)
          .send(text);
      if (mounted) _controller.clear();
    } on Exception catch (error) {
      // Il testo resta nel campo: si può riprovare.
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 4,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: MessageValidators.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.writeMessage,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              if (_sending)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: l10n.sendMessage,
                  icon: const Icon(Icons.send),
                  onPressed: () => unawaited(_send()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
