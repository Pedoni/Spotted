import 'package:spotted/features/tags/domain/entities/tag.dart';
import 'package:spotted/features/tags/domain/repositories/tags_repository.dart';

class GetAllTags {
  const GetAllTags(this._repository);

  final TagsRepository _repository;

  Future<List<Tag>> call() => _repository.getAllTags();
}
