import 'package:spotted/features/reports/domain/entities/channel_report.dart';
import 'package:spotted/features/reports/domain/repositories/reports_repository.dart';

class GetChannelReports {
  const GetChannelReports(this._repository);

  final ReportsRepository _repository;

  Future<List<ChannelReport>> call({
    required String channelId,
    required int offset,
    required int limit,
  }) => _repository.getChannelReports(
    channelId: channelId,
    offset: offset,
    limit: limit,
  );
}
