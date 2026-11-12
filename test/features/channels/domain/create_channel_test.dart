import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/usecases/create_channel.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeChannelsRepository repository;
  late CreateChannel createChannel;

  setUp(() {
    repository = FakeChannelsRepository();
    createChannel = CreateChannel(repository, Random(7));
  });

  test('genera lo slug dal nome e normalizza i campi opzionali', () async {
    final channel = await createChannel(
      name: '  Spotted Pisa ',
      description: '   ',
      municipalityId: ' 050026 ',
      topicId: 't-uni',
    );

    expect(channel.slug, 'spotted-pisa');
    final call = repository.createCalls.single;
    expect(call['name'], 'Spotted Pisa');
    expect(call['description'], isNull);
    expect(call['municipalityId'], '050026');
    expect(call['topicId'], 't-uni');
  });

  test('slug già usato: riprova con un suffisso', () async {
    repository.takenSlugs = {'spotted-pisa'};

    final channel = await createChannel(name: 'Spotted Pisa');

    expect(channel.slug, matches(RegExp(r'^spotted-pisa-[a-z0-9]{4}$')));
    expect(repository.createCalls, hasLength(2));
  });

  test('troppe collisioni: ConflictFailure', () async {
    repository.createError = const ConflictFailure();

    await expectLater(
      createChannel(name: 'Spotted Pisa'),
      throwsA(isA<ConflictFailure>()),
    );
    expect(repository.createCalls, hasLength(CreateChannel.maxAttempts));
  });

  test('altri errori non vengono ritentati', () async {
    repository.createError = const NetworkFailure();

    await expectLater(
      createChannel(name: 'Spotted Pisa'),
      throwsA(isA<NetworkFailure>()),
    );
    expect(repository.createCalls, hasLength(1));
  });

  test('dati non validi: ValidationFailure e nessuna chiamata', () async {
    await expectLater(
      createChannel(name: 'ab'),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.createCalls, isEmpty);
  });

  test('senza comune: il comune è vuoto, non un testo vuoto', () async {
    await createChannel(name: 'Università online');
    await createChannel(name: 'Altro canale', municipalityId: '   ');

    expect(repository.createCalls[0]['municipalityId'], isNull);
    expect(repository.createCalls[1]['municipalityId'], isNull);
  });
}
