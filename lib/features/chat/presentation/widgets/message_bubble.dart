import 'package:flutter/material.dart';
import 'package:spotted/core/theme/app_shapes.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';

/// Un messaggio: a destra se è dell'utente, a sinistra se è dell'altro. È un
/// fumetto: l'angolo dalla parte di chi scrive è quasi dritto. La larghezza
/// segue il testo, fino all'80% dello schermo.
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = message.isMine;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(message.createdAt.toLocal()),
      alwaysUse24HourFormat: true,
    );
    // Nello scheletro le bolle sono tutte neutre.
    final color = mine && !isSkeleton(context)
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppShapes.messageRadius(mine: mine),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.content),
              const SizedBox(height: 2),
              Text(time, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
