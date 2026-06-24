import 'package:likha/domain/auth/repositories/auth_repository.dart';

class UsernameExists {
  final AuthRepository _repository;

  UsernameExists(this._repository);

  Future<bool> call(String username) {
    return _repository.usernameExists(username: username);
  }
}
