import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/events/domain/event_validators.dart';
import 'package:spotted/features/events/domain/usecases/create_event.dart';
import 'package:spotted/features/events/domain/usecases/update_event.dart';

import '../../../helpers/fake_events.dart';

void main() {
  final start = DateTime(2030, 5, 10, 18);

  group('EventValidators', () {
    test('il titolo va da 1 a 100 caratteri, senza gli spazi ai bordi', () {
      expect(EventValidators.isValidTitle(' '), isFalse);
      expect(EventValidators.isValidTitle('a'), isTrue);
      expect(EventValidators.isValidTitle('a' * 100), isTrue);
      expect(EventValidators.isValidTitle('a' * 101), isFalse);
    });

    test('la descrizione va da 1 a 2000 caratteri', () {
      expect(EventValidators.isValidDescription(''), isFalse);
      expect(EventValidators.isValidDescription('a' * 2000), isTrue);
      expect(EventValidators.isValidDescription('a' * 2001), isFalse);
    });

    test('il luogo è facoltativo e fino a 100 caratteri', () {
      expect(EventValidators.isValidLocation(''), isTrue);
      expect(EventValidators.isValidLocation('a' * 100), isTrue);
      expect(EventValidators.isValidLocation('a' * 101), isFalse);
    });

    test('la fine non può essere prima dell inizio', () {
      expect(EventValidators.areValidDates(start, null), isTrue);
      expect(EventValidators.areValidDates(start, start), isTrue);
      expect(
        EventValidators.areValidDates(
          start,
          start.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
      expect(
        EventValidators.areValidDates(
          start,
          start.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });
  });

  group('CreateEvent', () {
    test('toglie gli spazi ai bordi e pubblica', () async {
      final repository = FakeEventsRepository();

      await CreateEvent(repository)(
        channelId: 'c1',
        title: '  Aperitivo ',
        description: '\nPer conoscersi\n',
        location: ' Aula magna ',
        startsAt: start,
      );

      expect(repository.createCalls.single, {
        'channelId': 'c1',
        'title': 'Aperitivo',
        'description': 'Per conoscersi',
        'location': 'Aula magna',
        'startsAt': start,
        'endsAt': null,
      });
    });

    test('un luogo vuoto o di soli spazi diventa nessun luogo', () async {
      final repository = FakeEventsRepository();
      final create = CreateEvent(repository);

      await create(
        channelId: 'c1',
        title: 't',
        description: 'd',
        location: '   ',
        startsAt: start,
      );
      await create(
        channelId: 'c1',
        title: 't',
        description: 'd',
        startsAt: start,
      );

      expect(repository.createCalls.map((c) => c['location']), [null, null]);
    });

    test(
      'campi o date non validi: ValidationFailure, senza chiamare',
      () async {
        final repository = FakeEventsRepository();
        final create = CreateEvent(repository);

        await expectLater(
          create(
            channelId: 'c1',
            title: ' ',
            description: 'd',
            startsAt: start,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        await expectLater(
          create(channelId: 'c1', title: 't', description: '', startsAt: start),
          throwsA(isA<ValidationFailure>()),
        );
        await expectLater(
          create(
            channelId: 'c1',
            title: 't',
            description: 'd',
            location: 'a' * 101,
            startsAt: start,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        await expectLater(
          create(
            channelId: 'c1',
            title: 't',
            description: 'd',
            startsAt: start,
            endsAt: start.subtract(const Duration(hours: 1)),
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect(repository.createCalls, isEmpty);
      },
    );
  });

  group('UpdateEvent', () {
    test('toglie gli spazi ai bordi e salva', () async {
      final repository = FakeEventsRepository(events: [makeEvent(1)]);

      await UpdateEvent(repository)(
        eventId: 'e1',
        title: ' Nuovo ',
        description: ' Testo ',
        startsAt: start,
        endsAt: start.add(const Duration(hours: 2)),
      );

      expect(repository.updateCalls.single['title'], 'Nuovo');
      expect(repository.updateCalls.single['description'], 'Testo');
      expect(
        repository.updateCalls.single['endsAt'],
        start.add(const Duration(hours: 2)),
      );
    });

    test('fine prima dell inizio: ValidationFailure', () async {
      final repository = FakeEventsRepository(events: [makeEvent(1)]);

      await expectLater(
        UpdateEvent(repository)(
          eventId: 'e1',
          title: 't',
          description: 'd',
          startsAt: start,
          endsAt: start.subtract(const Duration(minutes: 5)),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.updateCalls, isEmpty);
    });
  });
}
