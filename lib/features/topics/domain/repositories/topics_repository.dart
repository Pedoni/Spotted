import 'package:spotted/features/topics/domain/entities/topic.dart';

abstract interface class TopicsRepository {
  /// Elenco fisso dei topic, ordinato per nome.
  Future<List<Topic>> getTopics();
}
