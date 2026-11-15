import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Supabase che non esce in rete: risponde con [handler] e registra le
/// richieste in [requests].
class MockSupabase {
  MockSupabase(this.handler) {
    client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await handler(request);
        // Postgrest legge `response.request`: va impostata.
        return http.Response(
          response.body,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
  }

  final Future<http.Response> Function(http.Request request) handler;
  final requests = <http.Request>[];
  late final SupabaseClient client;

  http.Request get lastRequest => requests.last;
}

http.Response jsonResponse(Object? body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Errore nel formato di PostgREST.
http.Response postgrestError(String code, String message, {int status = 400}) {
  return jsonResponse({'code': code, 'message': message}, status: status);
}

Map<String, dynamic> channelRow(
  String id, {
  String? name,
  String? topicId,
  String? place,
  String? description,
  String? municipalityId,
  String? provinceCode,
  String? regionName,
}) {
  return {
    'id': id,
    'name': name ?? 'Canale $id',
    'slug': 'canale-$id',
    'description': description,
    'place': place,
    'municipality_id': municipalityId,
    'province_code': provinceCode,
    'region_name': regionName,
    'topic_id': topicId,
    'created_at': '2026-01-01T10:00:00+00:00',
  };
}

Map<String, dynamic> spotRow(
  String id, {
  String? title,
  String? content,
  int? likeCount,
  int? commentCount,
  bool? likedByMe,
  String? status,
}) {
  return {
    'id': id,
    'channel_id': 'c1',
    'title': title ?? 'Spot $id',
    'content': content ?? 'Testo $id',
    'created_at': '2026-01-01T10:00:00+00:00',
    'like_count': ?likeCount,
    'comment_count': ?commentCount,
    'liked_by_me': ?likedByMe,
    'status': ?status,
  };
}

Map<String, dynamic> commentRow(
  String id, {
  String? content,
  String? authorUsername = 'luigi',
  bool isSpotAuthor = false,
  bool isMine = false,
  int likeCount = 0,
  bool likedByMe = false,
  String? status,
}) {
  return {
    'id': id,
    'spot_id': 's1',
    'content': content ?? 'Commento $id',
    'created_at': '2026-01-01T10:00:00+00:00',
    'author_username': isSpotAuthor ? null : authorUsername,
    'is_spot_author': isSpotAuthor,
    'is_mine': isMine,
    'like_count': likeCount,
    'liked_by_me': likedByMe,
    'status': ?status,
  };
}

Map<String, dynamic> reportRow(
  String id, {
  String kind = 'spot',
  String reason = 'spam',
  String? details,
}) {
  return {
    'id': id,
    'kind': kind,
    'spot_id': 's1',
    'spot_title': 'Titolo $id',
    'content': kind == 'spot' ? 'Testo $id' : 'Commento $id',
    'reason': reason,
    'details': details,
    'created_at': '2026-01-01T10:00:00+00:00',
  };
}

/// Riga di `my_chats_page` / `chat_detail`. Per il commentatore
/// (`iAmAuthor: false`) lo username dell'altro è nullo finché l'identità non è
/// rivelata.
Map<String, dynamic> chatRow(
  String id, {
  bool iAmAuthor = true,
  String? otherUsername = 'luigi',
  bool identityRevealed = false,
  String? lastMessage,
  bool? lastMessageIsMine,
}) {
  return {
    'id': id,
    'spot_id': 's1',
    'spot_title': 'Ombrello perso',
    'channel_name': 'Spotted Pisa',
    'channel_slug': 'spotted-pisa',
    'i_am_author': iAmAuthor,
    'other_username': otherUsername,
    'identity_revealed': identityRevealed,
    'created_at': '2026-01-01T10:00:00+00:00',
    'last_message': lastMessage,
    'last_message_at': lastMessage == null ? null : '2026-01-01T11:00:00+00:00',
    'last_message_is_mine': lastMessageIsMine,
  };
}

/// Riga di `chat_messages` / `send_message`.
Map<String, dynamic> messageRow(
  String id, {
  String? content,
  bool isMine = false,
}) {
  return {
    'id': id,
    'content': content ?? 'Messaggio $id',
    'created_at': '2026-01-01T10:00:00+00:00',
    'is_mine': isMine,
  };
}

/// Riga di `search_municipalities`.
Map<String, dynamic> municipalityRow(
  String code, {
  String name = 'Pisa',
  String provinceCode = 'PI',
  String provinceName = 'Pisa',
  String regionName = 'Toscana',
}) {
  return {
    'istat_code': code,
    'name': name,
    'province_code': provinceCode,
    'province_name': provinceName,
    'region_name': regionName,
  };
}
