import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/domain/setup/entities/school_config.dart';

/// Abstract contract for the school onboarding setup flow.
///
/// School codes are verified server-side against the Pi server.
/// The cloud test code is checked client-side (no server call).
/// QR payloads contain the plain school code text.
abstract class SchoolSetupService {
  /// Verifies a QR payload (plain school code text) via [resolveShortCode].
  Future<Either<Failure, SchoolConfig>> resolveQrPayload(String payload);

  /// Verifies a 6-char school code:
  /// - If it matches the cloud test code → connects to cloud URL (client-side)
  /// - Otherwise → sends to default Pi server for verification
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
