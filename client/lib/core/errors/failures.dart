import 'package:equatable/equatable.dart';

enum ErrorCategory {
  network,       // Offline/connectivity → suppress (return null)
  unauthorized,  // 401 → 'Session expired. Please log in again.'
  forbidden,     // 403 → "You don't have permission..."
  notFound,      // 404 → 'Resource not found.'
  serverError,   // 5xx → 'Something went wrong. Try again later.'
  cache,         // SQLite/local error → 'Something went wrong. Try again later.'
  validation,    // Client validation → pass through failure.message
  unknown,       // Fallback → 'Something went wrong. Try again later.'
}

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  ErrorCategory get category;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});

  @override
  ErrorCategory get category {
    if (statusCode == 401) return ErrorCategory.unauthorized;
    if (statusCode == 403) return ErrorCategory.forbidden;
    if (statusCode == 404) return ErrorCategory.notFound;
    if (statusCode != null && statusCode! >= 500) return ErrorCategory.serverError;
    if (statusCode == 400) return ErrorCategory.validation;
    return ErrorCategory.unknown;
  }

  @override
  List<Object> get props => [message, statusCode ?? ''];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);

  @override
  ErrorCategory get category => ErrorCategory.cache;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  @override
  ErrorCategory get category => ErrorCategory.network;
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);

  @override
  ErrorCategory get category => ErrorCategory.unauthorized;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);

  @override
  ErrorCategory get category => ErrorCategory.validation;
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
  ErrorCategory get category => ErrorCategory.unknown;

  @override
  List<Object> get props => [message, username];
}

class TooManyRequestsFailure extends Failure {
  final int remainingSeconds;

  const TooManyRequestsFailure(super.message, {required this.remainingSeconds});

  @override
  ErrorCategory get category => ErrorCategory.unknown;

  @override
  List<Object> get props => [message, remainingSeconds];
}

class InvalidCredentialsFailure extends Failure {
  final int attemptsRemaining;

  const InvalidCredentialsFailure(super.message, {required this.attemptsRemaining});

  @override
  ErrorCategory get category => ErrorCategory.unauthorized;

  @override
  List<Object> get props => [message, attemptsRemaining];
}
