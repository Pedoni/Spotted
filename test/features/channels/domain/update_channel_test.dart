import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/channels/domain/usecases/delete_channel.dart';
import 'package:spotted/features/channels/domain/usecases/update_channel.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeChannelsRepository repository;

  setUp(() {
    repository = FakeChannelsRepository(
      mine: [makeChannel(1, name: 'Spotted Pisa')],
    );
  });

  group('UpdateChannel', () {
    test('normalizza i campi e non cambia lo slug', () async {
      final channel = await UpdateChannel(repository)(
        channelId: 'c1',
        name: '  Spotted Pisa Nord ',
        description: '   ',
        municipalityId: ' 050026 ',
        topicId: 't-uni',
      );

      final call = repository.updateCalls.single;
      expect(call['channelId'], 'c1');
      expect(call['name'], 'Spotted Pisa Nord');
      expect(call['description'], isNull);
      expect(call['municipalityId'], '050026');
      expect(call['topicId'], 't-uni');
      expect(channel.slug, 'canale-1');
    });

    test('un nome troppo corto non arriva al repository', () {
      expect(
        () => UpdateChannel(repository)(channelId: 'c1', name: 'No'),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.updateCalls, isEmpty);
    });

    test('una descrizione troppo lunga non arriva al repository', () {
      expect(
        () => UpdateChannel(repository)(
          channelId: 'c1',
          name: 'Spotted Pisa',
          description: 'x' * 501,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.updateCalls, isEmpty);
    });

    test("l'errore del repository passa così com'è", () {
      repository.updateError = const PermissionFailure();

      expect(
        () => UpdateChannel(repository)(channelId: 'c1', name: 'Spotted'),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });

  group('DeleteChannel', () {
    test("chiede l'eliminazione del canale", () async {
      await DeleteChannel(repository)('c1');

      expect(repository.deleteCalls, ['c1']);
      expect(repository.mine, isEmpty);
    });

    test("l'errore del repository passa così com'è", () {
      repository.deleteError = const PermissionFailure();

      expect(
        () => DeleteChannel(repository)('c1'),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });
}
