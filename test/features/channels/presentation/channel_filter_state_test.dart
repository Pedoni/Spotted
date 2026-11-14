import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/channels/presentation/providers/channels_feed.dart';

void main() {
  const municipality = MunicipalityFilter(
    istatCode: '050026',
    label: 'Pisa (PI)',
  );
  const full = ChannelFilterState(
    topicId: 't-uni',
    regionName: 'Toscana',
    provinceCode: 'PI',
    provinceLabel: 'Pisa (PI)',
    municipality: municipality,
  );

  group('ChannelFilterState', () {
    test('senza filtri non ce ne sono di attivi', () {
      const state = ChannelFilterState(query: 'pisa');

      expect(state.activeCount, 0);
      expect(state.hasFilters, isFalse);
    });

    test('conta argomento, regione, provincia e comune', () {
      expect(const ChannelFilterState(topicId: 't').activeCount, 1);
      expect(
        const ChannelFilterState(
          topicId: 't',
          regionName: 'Toscana',
        ).activeCount,
        2,
      );
      expect(full.activeCount, 4);
      expect(full.hasFilters, isTrue);
    });

    test('il testo cercato non conta come filtro', () {
      expect(full.withQuery('pisa').activeCount, 4);
      expect(full.withQuery('pisa').query, 'pisa');
    });
  });

  group('ChannelFilter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    ChannelFilter notifier() => container.read(channelFilterProvider.notifier);
    ChannelFilterState state() => container.read(channelFilterProvider);

    test('apply imposta i filtri e tiene il testo cercato', () {
      notifier()
        ..setQuery('pisa')
        ..apply(full);

      expect(state().query, 'pisa');
      expect(state().topicId, 't-uni');
      expect(state().municipality, municipality);
      expect(state().provinceLabel, 'Pisa (PI)');
    });

    test('apply con altri filtri sostituisce i precedenti', () {
      notifier()
        ..apply(full)
        ..apply(const ChannelFilterState(regionName: 'Lazio'));

      expect(state().regionName, 'Lazio');
      expect(state().topicId, isNull);
      expect(state().provinceCode, isNull);
      expect(state().municipality, isNull);
    });

    test('clearFilters toglie i filtri e tiene il testo cercato', () {
      notifier()
        ..setQuery('pisa')
        ..apply(full)
        ..clearFilters();

      expect(state().query, 'pisa');
      expect(state().hasFilters, isFalse);
    });

    test('setQuery tiene i filtri', () {
      notifier()
        ..apply(full)
        ..setQuery('roma');

      expect(state().activeCount, 4);
      expect(state().query, 'roma');
    });
  });
}
