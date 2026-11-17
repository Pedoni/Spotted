import 'package:flutter/material.dart';
import 'package:spotted/core/format/date_time_format.dart';
import 'package:spotted/core/widgets/channel_avatar.dart';
import 'package:spotted/features/news/domain/entities/channel_news.dart';

/// Una news: titolo, testo e data. Con [showChannel] mostra anche il canale
/// (nelle liste che mescolano più canali). Con [maxBodyLines] il testo si
/// accorcia (nelle liste); senza, si legge tutto (nel dettaglio).
class NewsCard extends StatelessWidget {
  const NewsCard({
    required this.news,
    this.onTap,
    this.showChannel = false,
    this.onChannelTap,
    this.maxBodyLines,
    super.key,
  });

  final ChannelNews news;

  /// Apre il dettaglio. Se è `null` (siamo già nel dettaglio) la card non è
  /// toccabile.
  final VoidCallback? onTap;
  final bool showChannel;

  /// Apre il canale (toccando il suo nome).
  final VoidCallback? onChannelTap;
  final int? maxBodyLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = formatDateTime(context, news.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showChannel) ...[
                    ChannelAvatar(
                      name: news.channelName,
                      seed: news.channelId,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: showChannel
                        ? InkWell(
                            onTap: onChannelTap,
                            child: Text(
                              '${news.channelName} · $date',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : Text(date, style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                news.title,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                news.body,
                maxLines: maxBodyLines,
                overflow: maxBodyLines == null ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
