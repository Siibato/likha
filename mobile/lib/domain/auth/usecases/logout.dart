import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class Logout {
  final AuthRepository _repository;
  
  Logout(this._repository);
  
  ResultVoid call() {
    return _repository.logout();
  }
}