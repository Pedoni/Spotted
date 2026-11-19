import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/spots/domain/spot_validators.dart';
import 'package:spotted/features/spots/domain/usecases/create_spot.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeSpotsRepository repository;
  late CreateSpot createSpot;

  setUp(() {
    repository = FakeSpotsRepository();
    createSpot = CreateSpot(repository);
  });

  test('toglie gli spazi ai bordi di titolo e testo', () async {
    await createSpot(
      channelId: 'c1',
      title: '  Ciao  ',
      content: '\n Testo \n',
    );

    expect(repository.createCalls.single, {
      'channelId': 'c1',
      'title': 'Ciao',
      'content': 'Testo',
    });
  });

  test('titolo vuoto o di soli spazi: ValidationFailure', () async {
    await expectLater(
      createSpot(channelId: 'c1', title: '   ', content: 'Testo'),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.createCalls, isEmpty);
  });

  test('testo vuoto: ValidationFailure', () async {
    await expectLater(
      createSpot(channelId: 'c1', title: 'Titolo', content: ''),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('limiti di lunghezza: 100 e 2000 sì, uno in più no', () async {
    await createSpot(
      channelId: 'c1',
      title: 'a' * SpotValidators.maxTitleLength,
      content: 'b' * SpotValidators.maxContentLength,
    );
    expect(repository.createCalls, hasLength(1));

    await expectLater(
      createSpot(
        channelId: 'c1',
        title: 'a' * (SpotValidators.maxTitleLength + 1),
        content: 'b',
      ),
      throwsA(isA<ValidationFailure>()),
    );
    await expectLater(
      createSpot(
        channelId: 'c1',
        title: 'a',
        content: 'b' * (SpotValidators.maxContentLength + 1),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.createCalls, hasLength(1));
  });

  group('tag (solo il proprietario)', () {
    test('senza tag: lo spot nasce in attesa', () async {
      await createSpot(channelId: 'c1', title: 'Titolo', content: 'Testo');

      expect(repository.createTagCalls.single, isNull);
    });

    test('con i tag li passa al repository', () async {
      await createSpot(
        channelId: 'c1',
        title: 'Titolo',
        content: 'Testo',
        tags: ['crush', 'meme'],
      );

      expect(repository.createTagCalls.single, ['crush', 'meme']);
    });

    test('lista vuota o più di tre tag: ValidationFailure', () async {
      await expectLater(
        createSpot(
          channelId: 'c1',
          title: 'Titolo',
          content: 'Testo',
          tags: [],
        ),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        createSpot(
          channelId: 'c1',
          title: 'Titolo',
          content: 'Testo',
          tags: ['a', 'b', 'c', 'd'],
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.createCalls, isEmpty);
    });
  });
}
