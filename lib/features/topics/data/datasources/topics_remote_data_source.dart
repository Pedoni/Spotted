import 'package:spotted/features/topics/data/models/topic_dto.dart';
import 'package:spotted/features/topics/domain/entities/topic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicsRemoteDataSource {
  const TopicsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Topic>> getTopics() async {
    final rows = await _client
        .from('topics')
        .select(topicColumns)
        .order('name', ascending: true);
    return rows.map((row) => TopicDto.fromJson(row).toEntity()).toList();
  }
}
