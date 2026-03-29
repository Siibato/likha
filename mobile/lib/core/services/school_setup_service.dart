import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/setup/entities/school_config.dart';

/// Abstract contract for the school onboarding setup flow.
///
/// Implementations handle:
/// - Decrypting QR / short-code payloads
/// - Pinging a manual URL to verify connectivity
/// - Persisting and clearing the stored school config
abstract class SchoolSetupService {
  /// Decrypts a Base64-encoded QR payload and returns a [SchoolConfig].
  Future<Either<Failure, SchoolConfig>> resolveQrPayload(String base64Payload);

  /// Matches a 6-char code against the two known server codes (Pi + Cloud).
  Future<Either<Failure, SchoolConfig>> resolveShortCode(String code);

  /// Pings [url]/api/v1/health and returns a [SchoolConfig] on success.
  Future<Either<Failure, SchoolConfig>> connectManual(String url, String name);

  /// Persists [config] to SharedPreferences.
  Future<void> saveSchoolConfig(SchoolConfig config);

  /// Removes all school-related keys from SharedPreferences.
  Future<void> clearSchoolConfig();

  /// Returns the stored [SchoolConfig], or null if not yet set up.
  Future<SchoolConfig?> getSchoolConfig();
}
