import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/chat/domain/message_validators.dart';
import 'package:spotted/features/chat/domain/usecases/send_message.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  group('MessageValidators', () {
    test('da 1 a 5000 caratteri, senza contare gli spazi ai bordi', () {
      expect(MessageValidators.isValid(''), isFalse);
      expect(MessageValidators.isValid('   '), isFalse);
      expect(MessageValidators.isValid('a'), isTrue);
      expect(MessageValidators.isValid('a' * 5000), isTrue);
      expect(MessageValidators.isValid('  ${'a' * 5000}  '), isTrue);
      expect(MessageValidators.isValid('a' * 5001), isFalse);
    });
  });

  group('SendMessage', () {
    test('toglie gli spazi ai bordi e invia', () async {
      final repository = FakeChatRepository();

      final message = await SendMessage(repository)(
        chatId: 'ch1',
        content: '  Ciao  ',
      );

      expect(repository.sendCalls.single, (chatId: 'ch1', content: 'Ciao'));
      expect(message.content, 'Ciao');
      expect(message.isMine, isTrue);
    });

    test(
      'testo vuoto o troppo lungo: ValidationFailure, nessuna richiesta',
      () async {
        final repository = FakeChatRepository();

        await expectLater(
          SendMessage(repository)(chatId: 'ch1', content: '   '),
          throwsA(isA<ValidationFailure>()),
        );
        await expectLater(
          SendMessage(repository)(chatId: 'ch1', content: 'a' * 5001),
          throwsA(isA<ValidationFailure>()),
        );
        expect(repository.sendCalls, isEmpty);
      },
    );
  });
}
