import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotted/core/error/failure_message.dart';
import 'package:spotted/core/widgets/inline_progress.dart';
import 'package:spotted/features/comments/domain/comment_validators.dart';
import 'package:spotted/features/comments/presentation/providers/spot_comments_feed.dart';
import 'package:spotted/features/spots/domain/entities/spot.dart';
import 'package:spotted/features/spots/presentation/providers/spot_interaction.dart';
import 'package:spotted/l10n/app_localizations.dart';

/// Campo per scrivere un commento allo spot, con il pulsante Invia.
class CommentComposer extends ConsumerStatefulWidget {
  const CommentComposer({required this.spot, super.key});

  final Spot spot;

  @override
  ConsumerState<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<CommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (!CommentValidators.isValid(text) || _sending) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(spotCommentsFeedProvider(widget.spot.id).notifier)
          .add(text);
      ref
          .read(spotInteractionProvider(widget.spot.id).notifier)
          .addComments(widget.spot, 1);
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
                  maxLength: CommentValidators.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.writeComment,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: InlineProgress(),
                      )
                    : IconButton(
                        tooltip: l10n.sendComment,
                        icon: const Icon(Icons.send),
                        onPressed: () => unawaited(_send()),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
