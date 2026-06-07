import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/network/connectivity_service.dart';
import 'package:likha/core/services/caching_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late CachingService service;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivityService();
    service = CachingService(mockConnectivity);
  });

  group('CachingService.fetchWithCache', () {
    test('should return remote data when online and remote call succeeds', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final result = await service.fetchWithCache<String>(
        remoteCall: () async => 'remote_data',
        cacheFn: (_) async {},
        localCall: () async => 'cached_data',
      );

      expect(result, 'remote_data');
    });

    test('should cache data when remote call succeeds while online', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      String? cached;

      await service.fetchWithCache<String>(
        remoteCall: () async => 'remote_data',
        cacheFn: (data) async { cached = data; },
        localCall: () async => 'cached_data',
      );

      await Future.delayed(Duration.zero);
      expect(cached, 'remote_data');
    });

    test('should fall back to local cache when offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      final result = await service.fetchWithCache<String>(
        remoteCall: () async => 'remote_data',
        cacheFn: (_) async {},
        localCall: () async => 'cached_data',
      );

      expect(result, 'cached_data');
    });

    test('should fall back to local cache when network exception occurs', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final result = await service.fetchWithCache<String>(
        remoteCall: () async => throw NetworkException('Connection failed'),
        cacheFn: (_) async {},
        localCall: () async => 'cached_data',
      );

      expect(result, 'cached_data');
    });

    test('should rethrow ServerException when remote fails with server error', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      expect(
        () => service.fetchWithCache<String>(
          remoteCall: () async => throw ServerException('Server error'),
          cacheFn: (_) async {},
          localCall: () async => 'cached_data',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw CacheException when offline and cache fails', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      expect(
        () => service.fetchWithCache<String>(
          remoteCall: () async => 'remote_data',
          cacheFn: (_) async {},
          localCall: () async => throw CacheException('No cache available'),
        ),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
