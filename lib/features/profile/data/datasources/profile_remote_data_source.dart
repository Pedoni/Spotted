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
}
