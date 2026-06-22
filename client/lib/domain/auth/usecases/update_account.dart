import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class UpdateAccount {
  final AuthRepository _repository;

  UpdateAccount(this._repository);

  ResultFuture<MutationResult<User>> call(UpdateAccountParams params) {
    return _repository.updateAccount(
      userId: params.userId,
      firstName: params.firstName,
      lastName: params.lastName,
      role: params.role,
    );
  }
}

class UpdateAccountParams {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? role;

  UpdateAccountParams({
    required this.userId,
    this.firstName,
    this.lastName,
    this.role,
  });
}
