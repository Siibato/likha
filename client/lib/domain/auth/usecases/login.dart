import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/domain/auth/repositories/auth_repository.dart';

class Login {
  final AuthRepository _repository;
  
  Login(this._repository);
  
  ResultFuture<User> call(LoginParams params) {
    return _repository.login(
      username: params.username,
      password: params.password,
      deviceId: params.deviceId,
    );
  }
}

class LoginParams {
  final String username;
  final String password;
  final String? deviceId;
  
  LoginParams({
    required this.username,
    required this.password,
    this.deviceId,
  });
}