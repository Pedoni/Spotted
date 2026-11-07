import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/topics/data/datasources/topics_remote_data_source.dart';
import 'package:spotted/features/topics/data/repositories/topics_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  test('legge i topic ordinati per nome', () async {
    final supabase = MockSupabase(
      (_) async => jsonResponse([
        {'id': 't1', 'name': 'Scuola', 'description': 'Scuole e istituti'},
        {'id': 't2', 'name': 'Sport', 'description': null},
      ]),
    );

    final topics = await TopicsRemoteDataSource(supabase.client).getTopics();

    expect(topics.map((t) => t.name), ['Scuola', 'Sport']);
    expect(topics.first.description, 'Scuole e istituti');
    expect(topics.last.description, isNull);
    final request = supabase.lastRequest;
    expect(request.url.path, '/rest/v1/topics');
    expect(request.url.queryParameters['order'], startsWith('name.asc'));
  });

  test('errore del server: UnknownFailure', () async {
    final supabase = MockSupabase(
      (_) async => postgrestError('XX000', 'boom', status: 500),
    );
    final repository = TopicsRepositoryImpl(
      TopicsRemoteDataSource(supabase.client),
    );

    await expectLater(
      repository.getTopics(),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
