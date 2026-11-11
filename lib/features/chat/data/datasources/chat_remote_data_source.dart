import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/chat/data/models/chat_message_dto.dart';
import 'package:spotted/features/chat/data/models/chat_summary_dto.dart';
import 'package:spotted/features/chat/domain/entities/chat_message.dart';
import 'package:spotted/features/chat/domain/entities/chat_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `chats` e `messages` sono chiuse ai client (nessuno vede gli id dei
/// partecipanti): tutto passa da RPC che non restituiscono mai id di utenti.
/// Il database risponde `42501` a chi non è l'autore dello spot quando avvia
/// una chat o rivela l'identità.
class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<bool> isSpotAuthor(String spotId) async {
    return _client.rpc<bool>(
      'is_spot_author',
      params: {'p_spot_id': spotId},
    );
  }

  /// L'RPC restituisce `null` se il commento non esiste o non è visibile.
  Future<String> startChat(String commentId) async {
    final chatId = await _client.rpc<String?>(
      'start_chat',
      params: {'p_comment_id': commentId},
    );
    if (chatId == null) throw const NotFoundFailure();
    return chatId;
  }

  /// L'RPC restituisce `false` se la chat non esiste o l'identità era già
  /// rivelata.
  Future<void> revealIdentity(String chatId) async {
    final revealed = await _client.rpc<bool>(
      'reveal_identity',
      params: {'p_chat_id': chatId},
    );
    if (!revealed) throw const NotFoundFailure();
  }

  Future<List<ChatSummary>> getChats({
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'my_chats_page',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return _toChats(rows);
  }

  Future<ChatSummary> getChat(String chatId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'chat_detail',
      params: {'p_chat_id': chatId},
    );
    final chats = _toChats(rows);
    if (chats.isEmpty) throw const NotFoundFailure();
    return chats.single;
  }

  Future<List<ChatMessage>> getMessages({
    required String chatId,
    required int offset,
    required int limit,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'chat_messages',
      params: {'p_chat_id': chatId, 'p_limit': limit, 'p_offset': offset},
    );
    return _toMessages(rows);
  }

  /// L'RPC non restituisce righe se la chat non esiste, non è dell'utente o
  /// lo spot è rimosso.
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'send_message',
      params: {'p_chat_id': chatId, 'p_content': content},
    );
    final messages = _toMessages(rows);
    if (messages.isEmpty) throw const NotFoundFailure();
    return messages.single;
  }

  List<ChatSummary> _toChats(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => ChatSummaryDto.fromJson(row).toEntity())
      .toList();

  List<ChatMessage> _toMessages(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => ChatMessageDto.fromJson(row).toEntity())
      .toList();
}
