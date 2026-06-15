import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class ResetAccount {
  final AuthRepository _repository;

  ResetAccount(this._repository);

  ResultFuture<User> call(String userId) {
    return _repository.resetAccount(userId: userId);
  }
}
