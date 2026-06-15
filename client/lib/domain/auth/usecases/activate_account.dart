import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class ActivateAccount {
  final AuthRepository _repository;

  ActivateAccount(this._repository);

  ResultFuture<User> call(ActivateAccountParams params) {
    return _repository.activateAccount(
      username: params.username,
      password: params.password,
      confirmPassword: params.confirmPassword,
    );
  }
}

class ActivateAccountParams {
  final String username;
  final String password;
  final String confirmPassword;

  ActivateAccountParams({
    required this.username,
    required this.password,
    required this.confirmPassword,
  });
}
