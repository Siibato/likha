import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class LockAccount {
  final AuthRepository _repository;

  LockAccount(this._repository);

  ResultFuture<User> call(LockAccountParams params) {
    return _repository.lockAccount(
      userId: params.userId,
      locked: params.locked,
    );
  }
}

class LockAccountParams {
  final String userId;
  final bool locked;

  LockAccountParams({required this.userId, required this.locked});
}
