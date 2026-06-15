import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/auth/impl/auth_local_datasource_impl.dart';
import 'package:likha/data/models/auth/user_model.dart';

import '../../helpers/test_database.dart';

UserModel _sampleUser({String id = 'user-001', String role = 'teacher'}) {
  final now = DateTime(2026, 4, 19);
  return UserModel(
    id: id,
    username: 'testuser_$id',
    fullName: 'Test User',
    role: role,
    accountStatus: 'active',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AuthLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = AuthLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() => closeTestDatabase());

  group('AuthLocalDataSource', () {
    test('cacheCurrentUser and getCachedCurrentUser round-trips user data', () async {
      final user = _sampleUser();
      await datasource.cacheCurrentUser(user);
      final retrieved = await datasource.getCachedCurrentUser(user.id);
      expect(retrieved.id, user.id);
      expect(retrieved.username, user.username);
      expect(retrieved.fullName, user.fullName);
      expect(retrieved.role, user.role);
    });

    test('cacheAccounts persists multiple accounts', () async {
      final users = [
        _sampleUser(id: 'u1', role: 'teacher'),
        _sampleUser(id: 'u2', role: 'student'),
      ];
      await datasource.cacheAccounts(users);
      final accounts = await datasource.getCachedAccounts();
      expect(accounts.length, 2);
      final ids = accounts.map((u) => u.id).toSet();
      expect(ids, containsAll({'u1', 'u2'}));
    });

    test('cacheCurrentUser replaces existing user on conflict', () async {
      final original = _sampleUser(id: 'u1');
      await datasource.cacheCurrentUser(original);

      final updated = UserModel(
        id: 'u1',
        username: 'updated_user',
        fullName: 'Updated Name',
        role: 'teacher',
        accountStatus: 'active',
        isActive: true,
        createdAt: original.createdAt,
        updatedAt: DateTime.now(),
      );
      await datasource.cacheCurrentUser(updated);

      final retrieved = await datasource.getCachedCurrentUser('u1');
      expect(retrieved.username, 'updated_user');
    });

    test('getCachedAccounts returns empty list when no accounts cached', () async {
      final accounts = await datasource.getCachedAccounts();
      expect(accounts, isEmpty);
    });
  });
}
