import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/municipalities/domain/entities/municipality.dart';
import 'package:spotted/features/municipalities/domain/usecases/search_municipalities.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeMunicipalitiesRepository repository;
  late SearchMunicipalities search;

  setUp(() {
    repository = FakeMunicipalitiesRepository();
    search = SearchMunicipalities(repository);
  });

  test('con meno di 2 lettere non cerca e non fa nessuna richiesta', () async {
    expect(await search('p'), isEmpty);
    expect(await search(''), isEmpty);
    expect(await search('   '), isEmpty);
    expect(await search(' p '), isEmpty);
    expect(repository.searchCalls, isEmpty);
  });

  test('da 2 lettere in su cerca, togliendo gli spazi ai bordi', () async {
    final found = await search('  pis ');

    expect(repository.searchCalls.single.query, 'pis');
    expect(found.map((m) => m.name), ['Pisa', 'Pistoia']);
  });

  test('usa il limite di default o quello richiesto', () async {
    await search('pi');
    await search('pi', limit: 3);

    expect(repository.searchCalls[0].limit, SearchMunicipalities.defaultLimit);
    expect(repository.searchCalls[1].limit, 3);
  });

  group('Municipality', () {
    test("l'etichetta ha la sigla della provincia", () {
      expect(makeMunicipality().label, 'Pisa (PI)');
    });

    test('due comuni omonimi si distinguono dalla sigla', () {
      final co = makeMunicipality(
        code: '013123',
        name: 'Livo',
        provinceCode: 'CO',
        provinceName: 'Como',
        regionName: 'Lombardia',
      );
      final tn = makeMunicipality(
        code: '022121',
        name: 'Livo',
        provinceCode: 'TN',
        provinceName: 'Trento',
        regionName: 'Trentino-Alto Adige/Südtirol',
      );

      expect(co.name, tn.name);
      expect(co.label, isNot(tn.label));
      expect(co, isNot(tn));
    });
  });

  test('due comuni uguali per tutti i campi sono uguali', () {
    expect(
      makeMunicipality(),
      const Municipality(
        istatCode: '050026',
        name: 'Pisa',
        provinceCode: 'PI',
        provinceName: 'Pisa',
        regionName: 'Toscana',
      ),
    );
  });
}
