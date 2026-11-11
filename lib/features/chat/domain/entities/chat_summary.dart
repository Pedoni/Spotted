import 'package:equatable/equatable.dart';

/// Una chat tra l'autore di uno spot e chi lo ha commentato. Mai gli id dei
/// partecipanti: si sa solo se l'utente loggato è l'autore e, quando è
/// consentito, lo username dell'altro.
class ChatSummary extends Equatable {
  const ChatSummary({
    required this.id,
    required this.spotId,
    required this.spotTitle,
    required this.channelName,
    required this.channelSlug,
    required this.iAmAuthor,
    required this.identityRevealed,
    required this.createdAt,
    this.otherUsername,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageIsMine,
  });

  final String id;
  final String spotId;
  final String spotTitle;
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
  ];
}
