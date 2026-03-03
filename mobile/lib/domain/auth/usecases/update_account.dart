import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class UpdateAccount {
  final AuthRepository _repository;

  UpdateAccount(this._repository);

  ResultFuture<User> call(UpdateAccountParams params) {
    return _repository.updateAccount(
      userId: params.userId,
      username: params.username,
      fullName: params.fullName,
      role: params.role,
    );
  }
}

class UpdateAccountParams {
  final String userId;
  final String? username;
  final String? fullName;
  final String? role;

  UpdateAccountParams({
    required this.userId,
    this.username,
    this.fullName,
    this.role,
  });
}
