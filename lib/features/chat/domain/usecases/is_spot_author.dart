import 'package:spotted/features/chat/domain/repositories/chat_repository.dart';

class IsSpotAuthor {
  const IsSpotAuthor(this._repository);

  final ChatRepository _repository;

  Future<bool> call(String spotId) => _repository.isSpotAuthor(spotId);
}
