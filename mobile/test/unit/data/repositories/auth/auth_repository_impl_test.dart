import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/repositories/auth/auth_repository_impl.dart';

import '../../../../helpers/mock_datasources.dart';
import '../../../../helpers/mock_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

UserModel _fakeUser({String id = 'u-1', String role = 'teacher'}) => UserModel(
      id: id,
      username: 'testuser',
      fullName: 'Test User',
      role: role,
      accountStatus: 'activated',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );

AuthResponseModel _fakeAuthResponse({String userId = 'u-1'}) => AuthResponseModel(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresIn: 3600,
      user: _fakeUser(id: userId),
    );

AuthRepositoryImpl _buildRepo({
  required MockAuthLocalDataSource local,
  required MockAuthRemoteDataSource remote,
  required MockServerReachabilityService reachability,
  required MockStorageService storage,
  bool isServerReachable = true,
}) {
  when(() => reachability.isServerReachable).thenReturn(isServerReachable);
  return AuthRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    serverReachabilityService: reachability,
    storageService: storage,
    syncQueue: MockSyncQueue(),
    localDatabase: MockLocalDatabase(),
    classLocalDataSource: MockClassLocalDataSource(),
    assignmentLocalDataSource: MockAssignmentLocalDataSource(),
    assessmentLocalDataSource: MockAssessmentLocalDataSource(),
    learningMaterialLocalDataSource: MockLearningMaterialLocalDataSource(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockAuthLocalDataSource local;
  late MockAuthRemoteDataSource remote;
  late MockServerReachabilityService reachability;
  late MockStorageService storage;

  setUp(() {
    local = MockAuthLocalDataSource();
    remote = MockAuthRemoteDataSource();
    reachability = MockServerReachabilityService();
    storage = MockStorageService();
    dotenv.testLoad(fileInput: '');
    when(() => storage.getUserId()).thenAnswer((_) async => null);
    when(() => storage.isAuthenticated()).thenAnswer((_) async => false);
    when(() => local.cacheCurrentUser(any())).thenAnswer((_) async {});
    when(() => storage.saveUserRole(any())).thenAnswer((_) async {});

    registerFallbackValue(_fakeUser());
  });

  group('AuthRepositoryImpl', () {
    group('login — success', () {
      test('calls remote, caches user and returns Right(user)', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
        );
        when(() => remote.login(
              username: any(named: 'username'),
              password: any(named: 'password'),
              deviceId: any(named: 'deviceId'),
            )).thenAnswer((_) async => _fakeAuthResponse());

        final result = await repo.login(username: 'testuser', password: 'pass');

        expect(result.isRight(), isTrue);
        result.fold(
          (f) => fail('Expected Right, got $f'),
          (user) => expect(user.id, 'u-1'),
        );
      });
    });

    group('login — failure', () {
      test('returns InvalidCredentialsFailure on wrong password', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
        );
        when(() => remote.login(
              username: any(named: 'username'),
              password: any(named: 'password'),
              deviceId: any(named: 'deviceId'),
            )).thenThrow(InvalidCredentialsException('Invalid credentials', attemptsRemaining: 4));

        final result = await repo.login(username: 'testuser', password: 'wrong');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<InvalidCredentialsFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns NetworkFailure on network error', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
        );
        when(() => remote.login(
              username: any(named: 'username'),
              password: any(named: 'password'),
              deviceId: any(named: 'deviceId'),
            )).thenThrow(NetworkException('No connection'));

        final result = await repo.login(username: 'testuser', password: 'pass');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<NetworkFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getCurrentUser — online', () {
      test('fetches from remote and caches locally', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
          isServerReachable: true,
        );
        when(() => remote.getCurrentUser()).thenAnswer((_) async => _fakeUser());

        final result = await repo.getCurrentUser();

        expect(result.isRight(), isTrue);
        verify(() => remote.getCurrentUser()).called(1);
        verify(() => local.cacheCurrentUser(any())).called(1);
      });
    });

    group('getCurrentUser — offline', () {
      test('reads from cache when server not reachable', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
          isServerReachable: false,
        );
        when(() => storage.getUserId()).thenAnswer((_) async => 'u-1');
        when(() => local.getCachedCurrentUser('u-1'))
            .thenAnswer((_) async => _fakeUser());

        final result = await repo.getCurrentUser();

        expect(result.isRight(), isTrue);
        verifyNever(() => remote.getCurrentUser());
      });

      test('returns UnauthorizedFailure when no stored userId', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
          isServerReachable: false,
        );
        when(() => storage.getUserId()).thenAnswer((_) async => null);

        final result = await repo.getCurrentUser();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('logout', () {
      test('calls remote logout and clears cache', () async {
        final repo = _buildRepo(
          local: local,
          remote: remote,
          reachability: reachability,
          storage: storage,
        );
        when(() => storage.getRefreshToken()).thenAnswer((_) async => 'rt');
        when(() => remote.logout(any())).thenAnswer((_) async {});
        when(() => local.clearAllCache()).thenAnswer((_) async {});

        final result = await repo.logout();

        expect(result, const Right(null));
        verify(() => remote.logout('rt')).called(1);
      });
    });
  });
}
