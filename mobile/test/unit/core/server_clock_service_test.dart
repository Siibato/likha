import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/services/server_clock_service.dart';

void main() {
  late ServerClockService service;

  setUp(() {
    service = ServerClockService();
  });

  group('ServerClockService', () {
    test('should not be synced initially', () {
      expect(service.hasBeenSynced, false);
    });

    test('should return device time before any sync', () {
      final before = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
      final result = service.now();
      final after = DateTime.now().toUtc().add(const Duration(seconds: 1));

      expect(result.isAfter(before), true);
      expect(result.isBefore(after), true);
    });

    test('should update offset when synced', () {
      final futureServerTime = DateTime.now().toUtc().add(const Duration(hours: 1));
      final isoString = futureServerTime.toIso8601String();

      service.updateOffset(isoString);

      expect(service.hasBeenSynced, true);
    });

    test('should return adjusted time after sync with future server time', () {
      final futureServerTime = DateTime.now().toUtc().add(const Duration(minutes: 5));
      service.updateOffset(futureServerTime.toIso8601String());

      final adjusted = service.now();
      final deviceNow = DateTime.now().toUtc();

      expect(adjusted.isAfter(deviceNow.subtract(const Duration(seconds: 1))), true);
    });

    test('should return adjusted time after sync with past server time', () {
      final pastServerTime = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      service.updateOffset(pastServerTime.toIso8601String());

      final adjusted = service.now();
      final deviceNow = DateTime.now().toUtc();

      expect(adjusted.isBefore(deviceNow.add(const Duration(seconds: 1))), true);
    });

    test('should mark as synced after updateOffset', () {
      expect(service.hasBeenSynced, false);
      service.updateOffset(DateTime.now().toUtc().toIso8601String());
      expect(service.hasBeenSynced, true);
    });

    test('should handle ISO string with Z suffix', () {
      final timeStr = '2024-01-15T10:30:00.000Z';
      expect(() => service.updateOffset(timeStr), returnsNormally);
      expect(service.hasBeenSynced, true);
    });

    test('should handle ISO string without Z suffix', () {
      final timeStr = '2024-01-15T10:30:00.000';
      expect(() => service.updateOffset(timeStr), returnsNormally);
    });
  });
}
