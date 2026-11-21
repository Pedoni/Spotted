import 'package:equatable/equatable.dart';
import 'package:spotted/features/chat/domain/entities/chat_kind.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';

/// Una chat tra l'autore di uno spot e chi lo ha commentato. Mai gli id dei
/// partecipanti: si sa solo se l'utente loggato è l'autore e, quando è
/// consentito, lo username dell'altro.
class ChatSummary extends Equatable {
  const ChatSummary({
    required this.id,
    required this.channelName,
    required this.channelSlug,
    required this.iAmAuthor,
    required this.identityRevealed,
    required this.createdAt,
    this.spotId,
    this.spotTitle,
    this.kind = ChatKind.spot,
    this.lastMessageKind,
    this.unread = false,
    this.otherUsername,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageIsMine,
  });

  final String id;

  /// Lo spot da cui nasce la chat. Solo per `ChatKind.spot`.
  final String? spotId;
  final String? spotTitle;

  /// Per una chat con un canale non c'è lo spot e `iAmAuthor` è vero per il
  /// proprietario, che risponde a nome del canale.
  final ChatKind kind;
  final String channelName;
  final String channelSlug;

  /// L'utente loggato è l'autore dello spot (e ha avviato la chat).
  final bool iAmAuthor;

  /// Lo username dell'altra persona. L'autore vede sempre quello del
  /// commentatore; il commentatore vede quello dell'autore solo a identità
  /// rivelata (altrimenti è `null`).
  final String? otherUsername;

  /// L'autore ha mostrato il suo username al commentatore.
  final bool identityRevealed;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool? lastMessageIsMine;
  final ChatMessageKind? lastMessageKind;

  /// L'altra parte ha scritto dopo l'ultima volta che l'utente ha letto la
  /// chat.
  final bool unread;

  bool get isChannelChat => kind == ChatKind.channel;

  /// Stato dopo che l'autore ha rivelato la sua identità.
  ChatSummary withIdentityRevealed() => ChatSummary(
    id: id,
    spotId: spotId,
    spotTitle: spotTitle,
    channelName: channelName,
    channelSlug: channelSlug,
    iAmAuthor: iAmAuthor,
    identityRevealed: true,
    createdAt: createdAt,
    otherUsername: otherUsername,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
    lastMessageIsMine: lastMessageIsMine,
    kind: kind,
    lastMessageKind: lastMessageKind,
    unread: unread,
  );

  /// Stato dopo che l'utente ha letto la chat.
  ChatSummary withUnread({required bool unread}) => ChatSummary(
    id: id,
    spotId: spotId,
    spotTitle: spotTitle,
    channelName: channelName,
    channelSlug: channelSlug,
    iAmAuthor: iAmAuthor,
    identityRevealed: identityRevealed,
    createdAt: createdAt,
    otherUsername: otherUsername,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
    lastMessageIsMine: lastMessageIsMine,
    kind: kind,
    lastMessageKind: lastMessageKind,
    unread: unread,
  );

  @override
  List<Object?> get props => [
    id,
    spotId,
    spotTitle,
    channelName,
    channelSlug,
    iAmAuthor,
    otherUsername,
    identityRevealed,
    createdAt,
    lastMessage,
    lastMessageAt,
    lastMessageIsMine,
    kind,
    lastMessageKind,
    unread,
  ];
}
