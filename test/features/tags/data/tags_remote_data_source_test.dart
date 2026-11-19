import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/tags/data/datasources/tags_remote_data_source.dart';
import 'package:spotted/features/tags/data/repositories/tags_repository_impl.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;

  const rows = [
    {'slug': 'curiosita', 'label': 'Curiosità', 'category': 'Generici'},
    {'slug': 'esami', 'label': 'Esami', 'category': 'Didattica e studio'},
  ];

  TagsRemoteDataSource respondWith(Object body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    return TagsRemoteDataSource(supabase.client);
  }

  test("getAllTags chiama l'RPC all_tags e legge i tag in ordine", () async {
    final dataSource = respondWith(rows);

    final tags = await dataSource.getAllTags();

    expect(supabase.lastRequest.url.path, '/rest/v1/rpc/all_tags');
    expect(tags, const [
      Tag(slug: 'curiosita', label: 'Curiosità', category: 'Generici'),
      Tag(slug: 'esami', label: 'Esami', category: 'Didattica e studio'),
    ]);
  });

  test("getChannelTags chiama l'RPC channel_tags con il canale", () async {
    final dataSource = respondWith(rows);

    final tags = await dataSource.getChannelTags('c1');

    expect(supabase.lastRequest.url.path, '/rest/v1/rpc/channel_tags');
    expect(jsonDecode(supabase.lastRequest.body), {'p_channel_id': 'c1'});
    expect(tags.map((t) => t.slug), ['curiosita', 'esami']);
  });

  test('errori: la rete diventa NetworkFailure', () async {
    supabase = MockSupabase((_) async => throw const NetworkFailure());
    final repository = TagsRepositoryImpl(
      TagsRemoteDataSource(supabase.client),
    );

    await expectLater(
      repository.getAllTags(),
      throwsA(isA<Failure>()),
    );
  });
}
