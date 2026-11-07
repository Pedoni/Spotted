import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('isUsernameAvailable', () {
    test('libero se nessun profilo ha quello username', () async {
      final supabase = MockSupabase((_) async => jsonResponse(<Object>[]));

      final available = await AuthRemoteDataSource(
        supabase.client,
      ).isUsernameAvailable('mario_88');

      expect(available, isTrue);
      final request = supabase.lastRequest;
      expect(request.url.path, '/rest/v1/profiles');
      expect(request.url.queryParameters['username'], 'eq.mario_88');
      // Chiede solo l'id: nome e cognome non sono leggibili dai client.
      expect(request.url.queryParameters['select'], 'id');
    });

    test('occupato se esiste già un profilo', () async {
      final supabase = MockSupabase(
        (_) async => jsonResponse([
          {'id': 'u1'},
        ]),
      );

      final available = await AuthRemoteDataSource(
        supabase.client,
      ).isUsernameAvailable('mario_88');

      expect(available, isFalse);
    });
  });
}
