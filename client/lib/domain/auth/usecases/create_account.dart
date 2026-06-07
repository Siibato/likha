import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class CreateAccount {
  final AuthRepository _repository;

  CreateAccount(this._repository);

  ResultFuture<User> call(CreateAccountParams params) {
    return _repository.createAccount(
      username: params.username,
      fullName: params.fullName,
      role: params.role,
    );
  }
}

class CreateAccountParams {
  final String username;
  final String fullName;
  final String role;

  CreateAccountParams({
    required this.username,
    required this.fullName,
    required this.role,
  });
}
