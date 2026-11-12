import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/spots/domain/usecases/get_channel_spots.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeSpotsRepository repository;
  late GetChannelSpots getChannelSpots;

  setUp(() {
    repository = FakeSpotsRepository(
      spots: [
        makeSpot(1, title: 'Ombrello perso'),
        makeSpot(2, title: 'Perché non rispondi?'),
        makeSpot(3, title: 'Sconto'),
      ],
    );
    getChannelSpots = GetChannelSpots(repository);
  });

  Future<List<String>> titles({String? query}) async {
    final spots = await getChannelSpots(
      channelId: 'c1',
      offset: 0,
      limit: 20,
      query: query,
    );
    return spots.map((s) => s.title).toList();
  }

  group('senza ricerca', () {
    test('restituisce tutti gli spot', () async {
      expect(await titles(), hasLength(3));
      expect(repository.queries.single, isNull);
    });

    test('un testo vuoto o di soli spazi vale come nessuna ricerca', () async {
      expect(await titles(query: ''), hasLength(3));
      expect(await titles(query: '   '), hasLength(3));
      expect(repository.queries, [null, null]);
    });
  });

  group('con ricerca', () {
    test('passa il testo senza spazi ai bordi', () async {
      await titles(query: '  ombrello ');

      expect(repository.queries.single, 'ombrello');
    });

    test('con meno di 2 lettere non cerca e non fa richieste', () async {
      expect(await titles(query: 'o'), isEmpty);
      expect(await titles(query: ' o '), isEmpty);

      expect(repository.listCalls, isEmpty);
    });

    test('da 2 lettere in su cerca', () async {
      expect(await titles(query: 'om'), ['Ombrello perso']);
    });

    test('non distingue maiuscole e accenti', () async {
      expect(await titles(query: 'PERCHE'), ['Perché non rispondi?']);
      expect(await titles(query: 'perché'), ['Perché non rispondi?']);
    });

    test('nessun risultato: elenco vuoto', () async {
      expect(await titles(query: 'zzzz'), isEmpty);
    });
  });

  group('SpotValidators', () {
    test('searchText toglie gli spazi e dà null se è vuoto', () {
      expect(SpotValidators.searchText('  ciao '), 'ciao');
      expect(SpotValidators.searchText(''), isNull);
      expect(SpotValidators.searchText('   '), isNull);
      expect(SpotValidators.searchText(null), isNull);
    });

    test('la ricerca parte da 2 lettere, senza contare gli spazi ai bordi', () {
      expect(SpotValidators.minSearchLength, 2);
      expect(SpotValidators.isSearchLongEnough('a'), isFalse);
      expect(SpotValidators.isSearchLongEnough(' a '), isFalse);
      expect(SpotValidators.isSearchLongEnough('ab'), isTrue);
      expect(SpotValidators.isSearchLongEnough(' ab '), isTrue);
    });
  });
}
