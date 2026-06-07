import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository _repository;
  
  GetCurrentUser(this._repository);
  
  ResultFuture<User> call() {
    return _repository.getCurrentUser();
  }
}