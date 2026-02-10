import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/check_username_result.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class CheckUsername {
  final AuthRepository _repository;

  CheckUsername(this._repository);

  ResultFuture<CheckUsernameResult> call(String username) {
    return _repository.checkUsername(username: username);
  }
}
