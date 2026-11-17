import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/news/domain/news_validators.dart';
import 'package:spotted/features/news/domain/usecases/create_news.dart';
import 'package:spotted/features/news/domain/usecases/update_news.dart';

import '../../../helpers/fake_news.dart';

void main() {
  group('NewsValidators', () {
    test(
      'il titolo va da 1 a 100 caratteri, senza contare gli spazi ai bordi',
      () {
        expect(NewsValidators.isValidTitle(''), isFalse);
        expect(NewsValidators.isValidTitle('   '), isFalse);
        expect(NewsValidators.isValidTitle('a'), isTrue);
        expect(NewsValidators.isValidTitle('a' * 100), isTrue);
        expect(NewsValidators.isValidTitle('a' * 101), isFalse);
        expect(NewsValidators.isValidTitle('  ${'a' * 100}  '), isTrue);
      },
    );

    test(
      'il testo va da 1 a 2000 caratteri, senza contare gli spazi ai bordi',
      () {
        expect(NewsValidators.isValidBody(''), isFalse);
        expect(NewsValidators.isValidBody('\n  '), isFalse);
        expect(NewsValidators.isValidBody('a'), isTrue);
        expect(NewsValidators.isValidBody('a' * 2000), isTrue);
        expect(NewsValidators.isValidBody('a' * 2001), isFalse);
      },
    );
  });

  group('CreateNews', () {
    test('toglie gli spazi ai bordi e pubblica', () async {
      final repository = FakeNewsRepository();

      await CreateNews(repository)(
        channelId: 'c1',
        title: '  Orari  ',
        body: '\nDa lunedì\n',
      );

      expect(repository.createCalls.single, {
        'channelId': 'c1',
        'title': 'Orari',
        'body': 'Da lunedì',
      });
    });

    test('titolo o testo vuoti: ValidationFailure, senza chiamare', () async {
      final repository = FakeNewsRepository();
      final create = CreateNews(repository);

      await expectLater(
        create(channelId: 'c1', title: ' ', body: 'x'),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        create(channelId: 'c1', title: 'x', body: ''),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.createCalls, isEmpty);
    });
  });

  group('UpdateNews', () {
    test('toglie gli spazi ai bordi e salva', () async {
      final repository = FakeNewsRepository(news: [makeNews(1)]);

      await UpdateNews(repository)(
        newsId: 'n1',
        title: ' Nuovo ',
        body: ' Testo ',
      );

      expect(repository.updateCalls.single, {
        'newsId': 'n1',
        'title': 'Nuovo',
        'body': 'Testo',
      });
    });

    test('titolo o testo troppo lunghi: ValidationFailure', () async {
      final repository = FakeNewsRepository(news: [makeNews(1)]);
      final update = UpdateNews(repository);

      await expectLater(
        update(newsId: 'n1', title: 'a' * 101, body: 'x'),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        update(newsId: 'n1', title: 'x', body: 'a' * 2001),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.updateCalls, isEmpty);
    });
  });
}
