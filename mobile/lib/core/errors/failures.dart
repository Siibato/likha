import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ActivationRequiredFailure extends Failure {
  final String username;
  final String? fullName;

  const ActivationRequiredFailure(
    super.message, {
    required this.username,
    this.fullName,
  });

  @override
  List<Object> get props => [message, username];
}

class TooManyRequestsFailure extends Failure {
  final int remainingSeconds;

  const TooManyRequestsFailure(super.message, {required this.remainingSeconds});

  @override
  List<Object> get props => [message, remainingSeconds];
}

class InvalidCredentialsFailure extends Failure {
  final int attemptsRemaining;

  const InvalidCredentialsFailure(super.message, {required this.attemptsRemaining});

  @override
  List<Object> get props => [message, attemptsRemaining];
}
