import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class GetAllAccounts {
  final AuthRepository _repository;

  GetAllAccounts(this._repository);

  ResultFuture<List<User>> call() {
    return _repository.getAllAccounts();
  }
}
