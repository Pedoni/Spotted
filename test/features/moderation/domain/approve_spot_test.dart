import 'package:flutter_test/flutter_test.dart';
import 'package:spotted/core/error/failure.dart';
import 'package:spotted/features/moderation/domain/usecases/approve_spot.dart';

import '../../../helpers/fake_repositories.dart';

void main() {
  late FakeModerationRepository repository;
  late ApproveSpot approveSpot;

  setUp(() {
    repository = FakeModerationRepository();
    approveSpot = ApproveSpot(repository);
  });

  test('da uno a tre tag: passa al repository', () async {
    await approveSpot('s1', ['crush']);
    await approveSpot('s2', ['crush', 'meme', 'animali']);

    expect(repository.approveCalls.map((c) => c.spotId), ['s1', 's2']);
    expect(repository.approveCalls[0].tags, ['crush']);
    expect(repository.approveCalls[1].tags, ['crush', 'meme', 'animali']);
  });

  test('nessun tag: ValidationFailure e niente richiesta', () {
    expect(() => approveSpot('s1', []), throwsA(isA<ValidationFailure>()));
    expect(repository.approveCalls, isEmpty);
  });

  test('più di tre tag: ValidationFailure', () {
    expect(
      () => approveSpot('s1', ['a', 'b', 'c', 'd']),
      throwsA(isA<ValidationFailure>()),
    );
    expect(repository.approveCalls, isEmpty);
  });
}
