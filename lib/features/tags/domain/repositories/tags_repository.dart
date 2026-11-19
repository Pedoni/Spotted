import 'package:spotted/features/tags/domain/entities/tag.dart';

/// Contratto dei tag. Le implementazioni lanciano un `Failure`.
abstract interface class TagsRepository {
  /// Tutti i tag, per mostrare il nome visibile sulle card.
  Future<List<Tag>> getAllTags();

  /// I tag tra cui scegliere in un canale: i generici più quelli del suo
  /// argomento, nell'ordine in cui si mostrano.
  Future<List<Tag>> getChannelTags(String channelId);
}
