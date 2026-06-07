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
      reason: params.reason,
    );
  }
}

class LockAccountParams {
  final String userId;
  final bool locked;
  final String? reason;

  LockAccountParams({required this.userId, required this.locked, this.reason});
}
