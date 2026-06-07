import 'package:likha/core/errors/exceptions.dart';

/// Typed mirror of the server's generic response envelope.
/// The server wraps all responses in: { success: bool, status_code: int, data?: T, error?: string }
class ApiResponse<T> {
  /// Whether the request was successful
  final bool success;

  /// HTTP status code from the server
  final int statusCode;

  /// The response data (null if success is false or no data returned)
  final T? data;

  /// Error message (set when success is false)
  final String? error;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
  });

  /// Factory to deserialize from server JSON response.
  /// Applies the custom [fromData] deserializer only if success is true.
  factory ApiResponse.fromJson(
    dynamic json,
    T Function(dynamic) fromData,
  ) {
    final map = json as Map<String, dynamic>;
    final success = map['success'] as bool;
    final statusCode = map['status_code'] as int? ?? 0;
    final error = map['error'] as String?;
    final rawData = map['data'];

    return ApiResponse(
      success: success,
      statusCode: statusCode,
      // Only deserialize data if successful and data is not null
      data: (success && rawData != null) ? fromData(rawData) : null,
      error: error,
    );
  }

  /// Unwraps the response, throwing [ServerException] if not successful.
  /// This follows Rust's Result::unwrap() pattern for clean error propagation.
  T unwrap() {
    if (!success) {
      throw ServerException(error ?? 'Request failed');
    }
    if (data == null) {
      throw ServerException('Response data is null');
    }
    return data as T;
  }
}
