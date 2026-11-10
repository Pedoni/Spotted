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
}
