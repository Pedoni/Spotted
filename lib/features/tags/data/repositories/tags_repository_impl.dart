import 'package:spotted/core/error/failure_guard.dart';
import 'package:spotted/features/tags/data/datasources/tags_remote_data_source.dart';
import 'package:spotted/features/tags/domain/entities/tag.dart';
import 'package:spotted/features/tags/domain/repositories/tags_repository.dart';

class TagsRepositoryImpl implements TagsRepository {
  const TagsRepositoryImpl(this._dataSource);

  final TagsRemoteDataSource _dataSource;

  @override
  Future<List<Tag>> getAllTags() {
    return guardFailures(_dataSource.getAllTags);
  }

  @override
  Future<List<Tag>> getChannelTags(String channelId) {
    return guardFailures(() => _dataSource.getChannelTags(channelId));
  }
}
