import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/features/channels/presentation/providers/channels_providers.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  test('senza la configurazione di Supabase non c è nessun indirizzo', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final urlOf = container.read(channelImageUrlProvider);

    expect(urlOf('c1/avatar-1.jpg'), isNull);
  });

  test('senza percorso non c è nessun indirizzo', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(channelImageUrlProvider)(null), isNull);
  });

  test('un canale porta i percorsi delle sue immagini', () {
    final channel = makeChannel(
      1,
      avatarPath: 'c1/avatar-1.jpg',
      coverPath: 'c1/cover-2.jpg',
    );

    expect(channel.avatarPath, 'c1/avatar-1.jpg');
    expect(channel.coverPath, 'c1/cover-2.jpg');
    // Le immagini fanno parte dell'uguaglianza: cambiarle aggiorna la UI.
    expect(channel, isNot(makeChannel(1)));
    expect(
      channel,
      makeChannel(
        1,
        avatarPath: 'c1/avatar-1.jpg',
        coverPath: 'c1/cover-2.jpg',
      ),
    );
  });
}
