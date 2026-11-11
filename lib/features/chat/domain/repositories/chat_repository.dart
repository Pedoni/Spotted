import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';

/// Contratto delle chat. Le implementazioni lanciano un `Failure`; chi non è
/// l'autore dello spot riceve `PermissionFailure` quando avvia una chat o
/// rivela l'identità.
abstract interface class ChatRepository {
  /// L'utente loggato è l'autore dello spot (mostra "Chatta" sui commenti).
  Future<bool> isSpotAuthor(String spotId);

  /// Avvia la chat con chi ha scritto il commento, o apre quella esistente, e
  /// restituisce il suo id. Lancia `NotFoundFailure` se il commento non esiste
  /// o non è visibile, `ValidationFailure` se è dell'utente stesso.
  Future<String> startChat(String commentId);

  /// L'autore mostra il suo username. Non si può annullare. Lancia
  /// `NotFoundFailure` se la chat non esiste o l'identità è già rivelata.
  Future<void> revealIdentity(String chatId);

  /// Pagina delle chat dell'utente, dalla più recente.
  Future<List<ChatSummary>> getChats({
    required int offset,
    required int limit,
  });

  /// Una chat. Lancia `NotFoundFailure` se non esiste o non è dell'utente.
  Future<ChatSummary> getChat(String chatId);

  /// Pagina di messaggi di una chat, dal più recente.
  Future<List<ChatMessage>> getMessages({
    required String chatId,
    required int offset,
    required int limit,
  });

  /// Scrive un messaggio. Lancia `NotFoundFailure` se la chat non esiste, non
  /// è dell'utente (il commentatore non ha ancora ricevuto un messaggio) o lo
  /// spot è rimosso.
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
  });
}
