import 'package:spotted/features/topics/domain/entities/topic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicsRemoteDataSource {
  const TopicsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Topic>> getTopics() async {
    final rows = await _client
        .from('topics')
        .select('id, name, description')
        .order('name');
    return rows
        .map(
          (row) => Topic(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String?,
          ),
        )
        .toList();
  }
}
