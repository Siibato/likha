import 'package:archive/archive.dart';

/// Utility class for compressing/decompressing file data
/// Uses hybrid strategy: only compress files > 5MB to save on CPU/time for small files
class CompressionUtil {
  static const int _compressionThreshold = 5 * 1024 * 1024; // 5MB

  /// Compress data if it exceeds threshold (5MB)
  /// Returns: (compressed_data, was_compressed)
  static (List<int>, bool) compressIfNeeded(List<int> data) {
    if (data.length > _compressionThreshold) {
      try {
        final encoder = GZipEncoder();
        final compressed = encoder.encode(data);
        if (compressed != null) {
          return (compressed, true);
        }
      } catch (_) {
        // If compression fails, return uncompressed
      }
    }
    // Don't compress files <= 5MB or if compression failed
    return (data, false);
  }

  /// Decompress data if it was compressed, otherwise return as-is
  static List<int> decompressIfNeeded(List<int> data, bool wasCompressed) {
    if (!wasCompressed) {
      return data;
    }

    try {
      final decoder = GZipDecoder();
      return decoder.decodeBytes(data);
    } catch (_) {
      // If decompression fails, return as-is (might already be uncompressed)
      return data;
    }
  }
}
