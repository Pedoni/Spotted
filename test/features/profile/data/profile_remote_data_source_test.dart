import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:spotted/features/profile/data/repositories/profile_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  test('legge il profilo con l RPC my_profile', () async {
    final supabase = MockSupabase(
      (_) async => jsonResponse([
        {
          'id': 'u1',
          'username': 'mario_88',
          'first_name': 'Mario',
          'last_name': 'Rossi',
          'birth_date': null,
          'created_at': '2026-01-01T10:00:00+00:00',
        },
      ]),
    );

    final profile = await ProfileRemoteDataSource(
      supabase.client,
    ).getMyProfile();

    expect(profile.username, 'mario_88');
    expect(profile.fullName, 'Mario Rossi');
    expect(supabase.lastRequest.method, 'POST');
    expect(supabase.lastRequest.url.path, '/rest/v1/rpc/my_profile');
  });

  test('senza nome e cognome', () async {
    final supabase = MockSupabase(
      (_) async => jsonResponse([
        {'id': 'u1', 'username': 'anon_user'},
      ]),
    );

    final profile = await ProfileRemoteDataSource(
      supabase.client,
    ).getMyProfile();

    expect(profile.fullName, isNull);
  });

  test('nessuna riga: NotFoundFailure', () async {
    final supabase = MockSupabase((_) async => jsonResponse(<Object>[]));
    final repository = ProfileRepositoryImpl(
      ProfileRemoteDataSource(supabase.client),
    );

    await expectLater(
      repository.getMyProfile(),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
