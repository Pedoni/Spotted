import 'package:spotted/features/tags/data/models/tag_dto.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// I tag stanno in una tabella chiusa ai client: si leggono con due RPC, che
/// li restituiscono già nell'ordine in cui si mostrano.
class TagsRemoteDataSource {
  const TagsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Tag>> getAllTags() async {
    final rows = await _client.rpc<List<dynamic>>('all_tags');
    return _toTags(rows);
  }

  Future<List<Tag>> getChannelTags(String channelId) async {
    final rows = await _client.rpc<List<dynamic>>(
      'channel_tags',
      params: {'p_channel_id': channelId},
    );
    return _toTags(rows);
  }

  List<Tag> _toTags(List<dynamic> rows) => rows
      .cast<Map<String, dynamic>>()
      .map((row) => TagDto.fromJson(row).toEntity())
      .toList();
}
