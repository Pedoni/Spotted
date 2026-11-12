import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/municipalities/data/datasources/municipalities_remote_data_source.dart';
import 'package:spotted/features/municipalities/data/repositories/municipalities_repository_impl.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabase supabase;
  late MunicipalitiesRemoteDataSource dataSource;

  Map<String, dynamic> sentBody() =>
      jsonDecode(supabase.lastRequest.body) as Map<String, dynamic>;

  void respondWith(Object? body, {int status = 200}) {
    supabase = MockSupabase((_) async => jsonResponse(body, status: status));
    dataSource = MunicipalitiesRemoteDataSource(supabase.client);
  }

  group('search', () {
    test("chiama l'RPC search_municipalities con testo e limite", () async {
      respondWith(<Object>[]);

      await dataSource.search('pis', limit: 8);

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/search_municipalities',
      );
      expect(sentBody(), {'p_query': 'pis', 'p_limit': 8});
    });

    test('legge codice, nome, provincia e regione', () async {
      respondWith([
        municipalityRow('050026'),
        municipalityRow(
          '021008',
          name: 'Bolzano',
          provinceCode: 'BZ',
          provinceName: 'Bolzano/Bozen',
          regionName: 'Trentino-Alto Adige/Südtirol',
        ),
      ]);

      final found = await dataSource.search('bo', limit: 8);

      expect(found, hasLength(2));
      expect(found[0].istatCode, '050026');
      expect(found[0].name, 'Pisa');
      expect(found[0].provinceCode, 'PI');
      expect(found[0].provinceName, 'Pisa');
      expect(found[0].regionName, 'Toscana');
      expect(found[0].label, 'Pisa (PI)');
      expect(found[1].provinceName, 'Bolzano/Bozen');
      expect(found[1].regionName, 'Trentino-Alto Adige/Südtirol');
    });

    test('nessun risultato: elenco vuoto', () async {
      respondWith(<Object>[]);

      expect(await dataSource.search('zzz', limit: 8), isEmpty);
    });
  });

  group('regioni e province', () {
    test("le regioni arrivano dall'RPC municipality_regions", () async {
      respondWith([
        {'region_name': 'Lazio'},
        {'region_name': 'Toscana'},
      ]);

      final regions = await dataSource.getRegions();

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/municipality_regions',
      );
      expect(regions, ['Lazio', 'Toscana']);
    });

    test('le province di una regione', () async {
      respondWith([
        {
          'province_code': 'PI',
          'province_name': 'Pisa',
          'region_name': 'Toscana',
        },
        {
          'province_code': 'PT',
          'province_name': 'Pistoia',
          'region_name': 'Toscana',
        },
      ]);

      final provinces = await dataSource.getProvinces(region: 'Toscana');

      expect(
        supabase.lastRequest.url.path,
        '/rest/v1/rpc/municipality_provinces',
      );
      expect(sentBody(), {'p_region': 'Toscana'});
      expect(provinces.map((p) => p.code), ['PI', 'PT']);
      expect(provinces.first.name, 'Pisa');
      expect(provinces.first.regionName, 'Toscana');
    });

    test('senza regione le chiede tutte (p_region nullo)', () async {
      respondWith(<Object>[]);

      await dataSource.getProvinces();

      expect(sentBody(), {'p_region': null});
    });
  });

  group('errori (repository)', () {
    late MunicipalitiesRepositoryImpl repository;

    void respondError(String code) {
      supabase = MockSupabase((_) async => postgrestError(code, 'errore'));
      repository = MunicipalitiesRepositoryImpl(
        MunicipalitiesRemoteDataSource(supabase.client),
      );
    }

    test('permesso negato (42501): PermissionFailure', () async {
      respondError('42501');

      await expectLater(
        repository.search('pis', limit: 8),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repository.getRegions(),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('risposta con tipi inattesi: UnknownFailure', () async {
      respondWith([
        {'istat_code': 1},
      ]);
      repository = MunicipalitiesRepositoryImpl(dataSource);

      await expectLater(
        repository.search('pis', limit: 8),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
