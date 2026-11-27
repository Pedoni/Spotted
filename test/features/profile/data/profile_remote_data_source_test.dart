import 'dart:convert';

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

  group('updateMyProfile', () {
    Map<String, dynamic> row({String? birth}) => {
      'id': 'u1',
      'username': 'mario_88',
      'first_name': 'Mario',
      'last_name': 'Rossi',
      'birth_date': birth,
      'created_at': '2026-01-01T10:00:00+00:00',
    };

    test("chiama l'RPC update_my_profile con i tre dati", () async {
      final supabase = MockSupabase(
        (_) async => jsonResponse([row(birth: '2000-01-31')]),
      );

      final profile = await ProfileRemoteDataSource(supabase.client)
          .updateMyProfile(
            firstName: 'Mario',
            lastName: 'Rossi',
            birthDate: DateTime(2000, 1, 31),
          );

      expect(supabase.lastRequest.url.path, '/rest/v1/rpc/update_my_profile');
      expect(jsonDecode(supabase.lastRequest.body), {
        'p_first_name': 'Mario',
        'p_last_name': 'Rossi',
        'p_birth_date': '2000-01-31',
      });
      expect(profile.firstName, 'Mario');
      expect(profile.birthDate, DateTime(2000, 1, 31));
    });

    test('senza data manda comunque p_birth_date, vuoto', () async {
      final supabase = MockSupabase((_) async => jsonResponse([row()]));

      final profile = await ProfileRemoteDataSource(
        supabase.client,
      ).updateMyProfile(firstName: 'Mario', lastName: 'Rossi');

      // Senza l'argomento PostgREST non troverebbe la funzione.
      final body =
          jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;
      expect(body.containsKey('p_birth_date'), isTrue);
      expect(body['p_birth_date'], isNull);
      expect(profile.birthDate, isNull);
    });

    test('i mesi e i giorni a una cifra hanno lo zero davanti', () async {
      final supabase = MockSupabase((_) async => jsonResponse([row()]));

      await ProfileRemoteDataSource(supabase.client).updateMyProfile(
        firstName: 'Mario',
        lastName: 'Rossi',
        birthDate: DateTime(1999, 3, 4),
      );

      final body =
          jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;
      expect(body['p_birth_date'], '1999-03-04');
    });

    test('nessuna riga: NotFoundFailure', () async {
      final supabase = MockSupabase((_) async => jsonResponse(<Object>[]));

      await expectLater(
        ProfileRemoteDataSource(supabase.client).updateMyProfile(
          firstName: 'Mario',
          lastName: 'Rossi',
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('dati non validi (23514): ValidationFailure', () async {
      final supabase = MockSupabase((_) async => postgrestError('23514', 'no'));
      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSource(supabase.client),
      );

      await expectLater(
        repository.updateMyProfile(firstName: 'Mario', lastName: 'Rossi'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  test('il profilo porta la data di nascita, se c è', () async {
    final supabase = MockSupabase(
      (_) async => jsonResponse([
        {
          'id': 'u1',
          'username': 'mario_88',
          'first_name': 'Mario',
          'last_name': 'Rossi',
          'birth_date': '1990-12-25',
          'created_at': '2026-01-01T10:00:00+00:00',
        },
      ]),
    );

    final profile = await ProfileRemoteDataSource(
      supabase.client,
    ).getMyProfile();

    expect(profile.birthDate, DateTime(1990, 12, 25));
  });
}
