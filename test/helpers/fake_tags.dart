import 'dart:async';

import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';
import 'package:spotted/features/tags/domain/repositories/tags_repository.dart';

/// Un piccolo elenco, come lo darebbe il database per un canale qualunque: due
/// categorie e quattro tag.
const fakeTags = [
  Tag(slug: 'crush', label: 'Crush', category: 'Generici'),
  Tag(slug: 'curiosita', label: 'Curiosità', category: 'Generici'),
  Tag(slug: 'meme', label: 'Meme', category: 'Generici'),
  Tag(slug: 'esami', label: 'Esami', category: 'Didattica e studio'),
];

/// I tag in memoria.
class FakeTagsRepository implements TagsRepository {
  FakeTagsRepository({List<Tag>? tags}) : tags = tags ?? fakeTags;

  List<Tag> tags;
  Failure? error;
  Completer<void>? gate;

  final channelCalls = <String>[];
  int allCalls = 0;

  @override
  Future<List<Tag>> getAllTags() async {
    allCalls++;
    if (error != null) throw error!;
    return tags;
  }

  @override
  Future<List<Tag>> getChannelTags(String channelId) async {
    channelCalls.add(channelId);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return tags;
  }
}
