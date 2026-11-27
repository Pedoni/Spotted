import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/profile/data/models/profile_dto.dart';
import 'package:spotted/features/profile/domain/entities/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Legge il profilo completo con l'RPC `my_profile()`: nome e cognome non
  /// sono leggibili direttamente dalla tabella.
  Future<Profile> getMyProfile() async {
    final rows = await _client.rpc<List<dynamic>>('my_profile');
    if (rows.isEmpty) throw const NotFoundFailure();
    return ProfileDto.fromJson(rows.first as Map<String, dynamic>).toEntity();
  }

  /// Usa l'RPC `update_my_profile`: la tabella non si scrive direttamente (lo
  /// username non deve cambiare). Gli argomenti ci sono sempre, anche la data
  /// vuota: senza `p_birth_date` PostgREST non troverebbe la funzione.
  Future<Profile> updateMyProfile({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'update_my_profile',
      params: {
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_birth_date': birthDate == null ? null : _day(birthDate),
      },
    );
    if (rows.isEmpty) throw const NotFoundFailure();
    return ProfileDto.fromJson(rows.first as Map<String, dynamic>).toEntity();
  }

  /// Il solo giorno, come lo vuole il database (`2000-01-31`).
  static String _day(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
        '${two(date.day)}';
  }
}
