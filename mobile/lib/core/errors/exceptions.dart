class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);
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
}
