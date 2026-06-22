import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class CreateAccount {
  final AuthRepository _repository;

  CreateAccount(this._repository);

  ResultFuture<MutationResult<User>> call(CreateAccountParams params) {
    return _repository.createAccount(
      username: params.username,
      firstName: params.firstName,
      lastName: params.lastName,
      role: params.role,
      learnerDetails: params.learnerDetails,
      teacherDetails: params.teacherDetails,
    );
  }
}

class CreateAccountParams {
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final Map<String, dynamic>? learnerDetails;
  final Map<String, dynamic>? teacherDetails;

  CreateAccountParams({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.learnerDetails,
    this.teacherDetails,
  });
}
