class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ActivationRequiredException implements Exception {
  final String message;
  final String username;
  final String? fullName;

  ActivationRequiredException(
    this.message, {
    required this.username,
    this.fullName,
  });

  @override
  String toString() => 'ActivationRequiredException: $message (user: $username)';
}

class TooManyRequestsException implements Exception {
  final String message;
  final int remainingSeconds;

  TooManyRequestsException(this.message, {required this.remainingSeconds});

  @override
  String toString() => 'TooManyRequestsException: $message (remaining: ${remainingSeconds}s)';
}

class InvalidCredentialsException implements Exception {
  final String message;
  final int attemptsRemaining;

  InvalidCredentialsException(this.message, {required this.attemptsRemaining});

  @override
  String toString() => 'InvalidCredentialsException: $message (attempts: $attemptsRemaining)';
}

class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
