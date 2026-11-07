import 'package:spotted/features/channels/domain/entities/channel.dart';

/// Colonne di `channels` leggibili dai client. `owner_id` è escluso di
/// proposito: il proprietario di un canale non è mostrato.
const channelColumns =
    'id, topic_id, name, slug, description, place, created_at';

abstract final class ChannelModel {
  static Channel fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      place: json['place'] as String?,
      topicId: json['topic_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
