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

http.Response jsonResponse(Object body, {int status = 200}) {
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
}) {
  return {
    'id': id,
    'name': name ?? 'Canale $id',
    'slug': 'canale-$id',
    'description': description,
    'place': place,
    'topic_id': topicId,
    'created_at': '2026-01-01T10:00:00+00:00',
  };
}
