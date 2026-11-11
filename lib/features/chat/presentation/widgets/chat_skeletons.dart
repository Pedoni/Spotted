import 'package:flutter/material.dart';
import 'package:spotted/core/widgets/skeleton.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:spotted/features/chat/presentation/widgets/chat_tile.dart';
import 'package:spotted/features/chat/presentation/widgets/message_bubble.dart';

/// Scheletro dell'elenco delle chat.
class ChatTilesSkeleton extends StatelessWidget {
  const ChatTilesSkeleton({this.count = 6, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            ChatTile(
              chat: ChatSummary(
                id: 'skeleton-$i',
                spotId: 'skeleton',
                spotTitle: 'Titolo dello spot',
                channelName: 'Nome del canale',
                channelSlug: 'skeleton',
                iAmAuthor: true,
                identityRevealed: false,
                createdAt: DateTime(2026),
                otherUsername: 'username',
                lastMessage: "L'ultimo messaggio della chat",
                lastMessageAt: DateTime(2026),
                lastMessageIsMine: false,
              ),
            ),
        ],
      ),
    );
  }
}

/// Scheletro dell'intestazione di una chat (lo spot da cui nasce).
class ChatHeaderSkeleton extends StatelessWidget {
  const ChatHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.article_outlined),
            title: const Text('Titolo dello spot'),
            subtitle: const Text('Nome del canale'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// Scheletro dei messaggi: bolle di lunghezze diverse, a destra e a sinistra.
class MessagesSkeleton extends StatelessWidget {
  const MessagesSkeleton({this.count = 5, super.key});

  final int count;

  static const _texts = [
    'Un messaggio di media lunghezza',
    'Ciao!',
    'Un messaggio più lungo che va su due righe nella bolla',
  ];

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            MessageBubble(
              message: ChatMessage(
                id: 'skeleton-$i',
                content: _texts[i % _texts.length],
                createdAt: DateTime(2026),
                isMine: i.isOdd,
              ),
            ),
        ],
      ),
    );
  }
}

/// I messaggi in scheletro dentro l'area della chat: ancorati in basso (i più
/// recenti stanno in basso) e tagliati se non ci stanno.
class MessagesSkeletonView extends StatelessWidget {
  const MessagesSkeletonView({this.count = 6, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      child: MessagesSkeleton(count: count),
    );
  }
}
