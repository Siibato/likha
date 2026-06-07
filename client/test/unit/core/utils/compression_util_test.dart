import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/utils/compression_util.dart';

void main() {
  group('CompressionUtil', () {
    group('compressIfNeeded', () {
      test('does not compress data at or below 5MB threshold', () {
        final smallData = List<int>.generate(1024 * 1024, (i) => i % 256); // 1MB
        final (result, wasCompressed) = CompressionUtil.compressIfNeeded(smallData);
        expect(wasCompressed, isFalse);
        expect(result, equals(smallData));
      });

      test('does not compress data exactly at 5MB boundary', () {
        final boundaryData = List<int>.generate(5 * 1024 * 1024, (i) => i % 256);
        final (_, wasCompressed) = CompressionUtil.compressIfNeeded(boundaryData);
        expect(wasCompressed, isFalse);
      });

      test('compresses data above 5MB threshold', () {
        // Use highly compressible data (all zeros)
        final largeData = List<int>.filled(6 * 1024 * 1024, 0);
        final (result, wasCompressed) = CompressionUtil.compressIfNeeded(largeData);
        expect(wasCompressed, isTrue);
        expect(result.length, lessThan(largeData.length));
      });

      test('compressed output is smaller than input for compressible data', () {
        final compressibleData = List<int>.filled(6 * 1024 * 1024, 42); // 6MB of same byte
        final (compressed, wasCompressed) = CompressionUtil.compressIfNeeded(compressibleData);
        expect(wasCompressed, isTrue);
        expect(compressed.length, lessThan(compressibleData.length));
      });

      test('returns empty list unchanged for empty input', () {
        final (result, wasCompressed) = CompressionUtil.compressIfNeeded([]);
        expect(wasCompressed, isFalse);
        expect(result, isEmpty);
      });

      test('does not compress minimal 1-byte data', () {
        final (result, wasCompressed) = CompressionUtil.compressIfNeeded([1]);
        expect(wasCompressed, isFalse);
        expect(result, equals([1]));
      });
    });

    group('decompressIfNeeded', () {
      test('returns data as-is when wasCompressed is false', () {
        final data = [1, 2, 3, 4, 5];
        final result = CompressionUtil.decompressIfNeeded(data, false);
        expect(result, equals(data));
      });

      test('round-trips: compress then decompress returns original data', () {
        final original = List<int>.filled(6 * 1024 * 1024, 99);
        final (compressed, wasCompressed) = CompressionUtil.compressIfNeeded(original);
        expect(wasCompressed, isTrue);

        final decompressed = CompressionUtil.decompressIfNeeded(compressed, true);
        expect(decompressed, equals(original));
      });

      test('round-trips with varied data pattern', () {
        final original = List<int>.generate(6 * 1024 * 1024, (i) => i % 256);
        final (compressed, wasCompressed) = CompressionUtil.compressIfNeeded(original);
        expect(wasCompressed, isTrue);

        final decompressed = CompressionUtil.decompressIfNeeded(compressed, true);
        expect(decompressed, equals(original));
      });

      test('returns data as-is when wasCompressed is true but data is corrupt', () {
        final corruptData = [0xFF, 0xFE, 0x00, 0x01, 0x02];
        final result = CompressionUtil.decompressIfNeeded(corruptData, true);
        expect(result, equals(corruptData));
      });

      test('returns empty list as-is when wasCompressed is false', () {
        final result = CompressionUtil.decompressIfNeeded([], false);
        expect(result, isEmpty);
      });
    });
  });
}
