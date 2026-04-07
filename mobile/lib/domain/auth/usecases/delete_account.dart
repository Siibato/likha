import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class DeleteAccount {
  final AuthRepository _repository;

  DeleteAccount(this._repository);

  ResultVoid call({required String userId}) {
    return _repository.deleteAccount(userId: userId);
  }
}
