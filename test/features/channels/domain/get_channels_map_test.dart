import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/channels/domain/usecases/get_channels_map.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeChannelsRepository repository;
  late GetChannelsMap getChannelsMap;

  setUp(() {
    repository = FakeChannelsRepository()..pins = [makePin('050026')];
    getChannelsMap = GetChannelsMap(repository);
  });

  test('restituisce i pin del repository', () async {
    final pins = await getChannelsMap();

    expect(pins.single.municipalityId, '050026');
  });

  test('passa i filtri così come sono', () async {
    await getChannelsMap(
      topicId: 't1',
      regionName: 'Toscana',
      provinceCode: 'PI',
      municipalityId: '050026',
    );

    final call = repository.mapCalls.single;
    expect(call.topicId, 't1');
    expect(call.regionName, 'Toscana');
    expect(call.provinceCode, 'PI');
    expect(call.municipalityId, '050026');
  });

  test('toglie gli spazi al testo; di soli spazi non è un filtro', () async {
    await getChannelsMap(query: '  pisa ');
    await getChannelsMap(query: '   ');
    await getChannelsMap();

    expect(repository.mapCalls[0].query, 'pisa');
    expect(repository.mapCalls[1].query, isNull);
    expect(repository.mapCalls[2].query, isNull);
  });
}
