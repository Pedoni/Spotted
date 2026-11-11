import 'package:equatable/equatable.dart';

/// Un messaggio di una chat. Mai chi lo ha scritto: si sa solo se è dell'utente
/// loggato.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  @override
  List<Object?> get props => [id, content, createdAt, isMine];
}
