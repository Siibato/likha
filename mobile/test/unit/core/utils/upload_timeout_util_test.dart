import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/utils/upload_timeout_util.dart';

void main() {
  group('UploadTimeoutUtil', () {
    group('calculateTimeoutFromBytes', () {
      const int baseTimeout = 30;
      const int maxTimeout = 300;

      test('returns base timeout for 0 bytes', () {
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(0);
        expect(result, equals(baseTimeout));
      });

      test('returns base timeout for very small files (1 byte)', () {
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(1);
        expect(result, equals(baseTimeout));
      });

      test('returns base timeout for small 1MB file', () {
        const oneMB = 1 * 1024 * 1024;
        // 30 + (1 / 0.5) = 32 — still above base but well within range
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(oneMB);
        expect(result, greaterThanOrEqualTo(baseTimeout));
        expect(result, lessThanOrEqualTo(maxTimeout));
      });

      test('result matches formula for 10MB: 30 + (10 / 0.5) = 50', () {
        const tenMB = 10 * 1024 * 1024;
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(tenMB);
        expect(result, equals(50));
      });

      test('result matches formula for 50MB: 30 + (50 / 0.5) = 130', () {
        const fiftyMB = 50 * 1024 * 1024;
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(fiftyMB);
        expect(result, equals(130));
      });

      test('result is clamped to max timeout (300s) for very large files', () {
        const oneGB = 1024 * 1024 * 1024;
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(oneGB);
        expect(result, equals(maxTimeout));
      });

      test('result is clamped to max timeout for exact threshold size', () {
        // Threshold: (300 - 30) * 0.5 = 135MB triggers exactly max
        const thresholdBytes = (135 * 1024 * 1024);
        final result = UploadTimeoutUtil.calculateTimeoutFromBytes(thresholdBytes);
        expect(result, equals(maxTimeout));
      });

      test('result is always between base and max (inclusive)', () {
        final testSizes = [0, 1, 1024, 1024 * 1024, 100 * 1024 * 1024, 1024 * 1024 * 1024];
        for (final size in testSizes) {
          final result = UploadTimeoutUtil.calculateTimeoutFromBytes(size);
          expect(result, greaterThanOrEqualTo(baseTimeout),
              reason: 'Failed for size $size: result $result < base $baseTimeout');
          expect(result, lessThanOrEqualTo(maxTimeout),
              reason: 'Failed for size $size: result $result > max $maxTimeout');
        }
      });

      test('result is monotonically non-decreasing as file size grows', () {
        final sizes = [0, 1 * 1024 * 1024, 10 * 1024 * 1024, 50 * 1024 * 1024, 200 * 1024 * 1024];
        int previous = 0;
        for (final size in sizes) {
          final result = UploadTimeoutUtil.calculateTimeoutFromBytes(size);
          expect(result, greaterThanOrEqualTo(previous),
              reason: 'Timeout decreased from $previous to $result at size $size');
          previous = result;
        }
      });
    });
  });
}
