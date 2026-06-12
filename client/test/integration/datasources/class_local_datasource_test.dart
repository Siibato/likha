import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/datasources/local/classes/impl/class_local_datasource_impl.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_model.dart';

import '../../helpers/test_database.dart';

const _teacherId = 'teacher-001';

ClassModel _sampleClass({String id = 'class-001'}) {
  final now = DateTime(2026, 4, 19);
  return ClassModel(
    id: id,
    title: 'Math 101',
    description: 'Basic Math',
    teacherId: _teacherId,
    teacherUsername: 'teacher01',
    teacherFullName: 'Mr. Teacher',
    isArchived: false,
    studentCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

UserModel _sampleStudent({String id = 'student-001'}) {
  final now = DateTime(2026, 4, 19);
  return UserModel(
    id: id,
    username: 'student_$id',
    fullName: 'Student Name',
    role: 'student',
    accountStatus: 'active',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late ClassLocalDataSourceImpl datasource;
  late SyncQueueImpl syncQueue;

  setUp(() async {
    await openFreshTestDatabase();
    syncQueue = SyncQueueImpl(LocalDatabase());
    datasource = ClassLocalDataSourceImpl(LocalDatabase(), syncQueue);
  });

  tearDown(() => closeTestDatabase());

  group('ClassLocalDataSource', () {
    test('cacheClasses and getCachedClasses returns list', () async {
      await datasource.cacheClasses([_sampleClass()]);
      final result = await datasource.getCachedClasses();
      expect(result.length, 1);
      expect(result.first.id, 'class-001');
      expect(result.first.title, 'Math 101');
    });

    test('getCachedClasses filters by teacherId', () async {
      await datasource.cacheClasses([
        _sampleClass(id: 'c1'),
        _sampleClass(id: 'c2'),
      ]);
      final result = await datasource.getCachedClasses(teacherId: _teacherId);
      expect(result.length, 2);
      for (final c in result) {
        expect(c.teacherId, _teacherId);
      }
    });

    test('createClassLocally inserts class with needsSync=1', () async {
      final classModel = await datasource.createClassLocally(
        title: 'Science 101',
        description: 'Basic Science',
        teacherId: _teacherId,
        teacherUsername: 'teacher01',
        teacherFullName: 'Mr. Teacher',
      );
      expect(classModel.id, isNotEmpty);

      final db = await LocalDatabase().database;
      final rows = await db.query(
        DbTables.classes,
        where: '${CommonCols.id} = ?',
        whereArgs: [classModel.id],
      );
      expect(rows.length, 1);
      expect(rows.first['title'], 'Science 101');
      expect(rows.first['needs_sync'], 1);
    });

    test('addStudentLocally and getCachedParticipants returns enrolled student', () async {
      await datasource.cacheClasses([_sampleClass()]);
      final student = _sampleStudent();
      // Students must exist in users table since participants FK references users
      final db = await LocalDatabase().database;
      final now = DateTime.now().toIso8601String();
      await db.insert(DbTables.users, {
        'id': student.id,
        'username': student.username,
        'full_name': student.fullName,
        'role': student.role,
        'account_status': student.accountStatus,
        'created_at': now,
        'updated_at': now,
        'needs_sync': 0,
      });

      await datasource.addStudentLocally(classId: 'class-001', student: student);
      final participants = await datasource.getCachedParticipants('class-001');
      expect(participants.length, 1);
      expect(participants.first.id, student.id);
    });

    test('getCachedClasses returns empty when nothing cached', () async {
      final result = await datasource.getCachedClasses();
      expect(result, isEmpty);
    });
  });
}
