import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/topics/data/datasources/topics_remote_data_source.dart';
import 'package:spotted/features/topics/domain/entities/topic.dart';
import 'package:spotted/features/topics/domain/repositories/topics_repository.dart';

class TopicsRepositoryImpl implements TopicsRepository {
  const TopicsRepositoryImpl(this._dataSource);

  final TopicsRemoteDataSource _dataSource;

  @override
  Future<List<Topic>> getTopics() => guardFailures(_dataSource.getTopics);
}
