import 'dart:io';

/// Utility class for calculating dynamic upload timeouts based on file size
class UploadTimeoutUtil {
  /// Base timeout in seconds (minimum timeout for any upload)
  static const int _baseTimeoutSeconds = 30;

  /// Maximum timeout in seconds (to prevent indefinite hangs)
  static const int _maxTimeoutSeconds = 300; // 5 minutes

  /// Estimated transfer speed in MB/s (conservative estimate)
  /// Assuming 500 KB/s = 0.5 MB/s
  static const double _estimatedTransferSpeedMBps = 0.5;

  /// Calculate dynamic timeout based on file size
  /// 
  /// Formula: base_timeout + (file_size_mb / estimated_transfer_speed)
  /// Capped between base_timeout and max_timeout
  /// 
  /// [filePath] - Path to the file being uploaded
  /// Returns timeout duration in seconds
  static int calculateTimeout(String filePath) {
    final file = File(filePath);
    final fileSizeBytes = file.lengthSync();
    final fileSizeMB = fileSizeBytes / (1024 * 1024);

    // Calculate timeout based on file size
    final calculatedTimeout = _baseTimeoutSeconds + (fileSizeMB / _estimatedTransferSpeedMBps);

    // Clamp between base and max timeout
    final timeoutSeconds = calculatedTimeout.clamp(
      _baseTimeoutSeconds.toDouble(),
      _maxTimeoutSeconds.toDouble(),
    ).toInt();

    return timeoutSeconds;
  }

  /// Calculate timeout directly from file size in bytes
  static int calculateTimeoutFromBytes(int fileSizeBytes) {
    final fileSizeMB = fileSizeBytes / (1024 * 1024);
    final calculatedTimeout = _baseTimeoutSeconds + (fileSizeMB / _estimatedTransferSpeedMBps);
    return calculatedTimeout.clamp(
      _baseTimeoutSeconds.toDouble(),
      _maxTimeoutSeconds.toDouble(),
    ).toInt();
  }
}
