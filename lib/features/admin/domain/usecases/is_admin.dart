import 'package:spotted/features/admin/domain/repositories/admin_repository.dart';

class IsAdmin {
  const IsAdmin(this._repository);

  final AdminRepository _repository;

  Future<bool> call() => _repository.isAdmin();
}
