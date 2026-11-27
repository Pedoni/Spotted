import 'package:equatable/equatable.dart';
import 'package:spotted/features/chat/domain/entities/chat_message_kind.dart';

/// Un messaggio di una chat. Mai chi lo ha scritto: si sa solo se è dell'utente
/// loggato.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isMine,
    this.kind = ChatMessageKind.text,
    this.spotId,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  /// `text` per i messaggi scritti da una persona. Gli altri sono messaggi di
  /// sistema (spot inviato, pubblicato, rifiutato): il testo è il titolo dello
  /// spot.
  final ChatMessageKind kind;

  /// Lo spot di un messaggio di sistema; `null` se è stato cancellato.
  final String? spotId;

  @override
  List<Object?> get props => [id, content, createdAt, isMine, kind, spotId];
}
