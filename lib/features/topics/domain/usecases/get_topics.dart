import 'package:spotted/features/topics/domain/entities/topic.dart';
import 'package:spotted/features/topics/domain/repositories/topics_repository.dart';

class GetTopics {
  const GetTopics(this._repository);

  final TopicsRepository _repository;

  Future<List<Topic>> call() => _repository.getTopics();
}
