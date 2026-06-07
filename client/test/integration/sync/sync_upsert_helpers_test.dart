import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_logger.dart';
import 'package:likha/core/sync/sync_upsert_helpers.dart';

import '../../helpers/test_database.dart';

void main() {
  late SyncUpsertHelpers helpers;

  setUp(() async {
    await openFreshTestDatabase();
    helpers = SyncUpsertHelpers(SyncLogger());
  });

  tearDown(() => closeTestDatabase());

  group('SyncUpsertHelpers', () {
    test('upsertClasses inserts new class records', () async {
      final db = await LocalDatabase().database;
      await helpers.upsertClasses(db, [
        {
          'id': 'class-001',
          'title': 'Math 101',
          'description': 'Math class',
          'teacher_id': 'teacher-001',
          'teacher_username': 'tuser',
          'teacher_full_name': 'Teacher Name',
          'is_archived': false,
          'is_advisory': false,
          'student_count': 0,
          'grading_period_type': 'quarter',
          'created_at': '2026-04-19T08:00:00',
          'updated_at': '2026-04-19T08:00:00',
        }
      ]);

      final rows = await db.query(DbTables.classes, where: 'id = ?', whereArgs: ['class-001']);
      expect(rows.length, 1);
      expect(rows.first['title'], 'Math 101');
      expect(rows.first['needs_sync'], 0);
    });

    test('upsertClasses updates existing class record (no duplicate)', () async {
      final db = await LocalDatabase().database;
      final record = {
        'id': 'class-001',
        'title': 'Old Title',
        'teacher_id': 'teacher-001',
        'teacher_username': 'tuser',
        'teacher_full_name': 'Teacher Name',
        'is_archived': false,
        'is_advisory': false,
        'student_count': 0,
        'grading_period_type': 'quarter',
        'created_at': '2026-04-19T08:00:00',
        'updated_at': '2026-04-19T08:00:00',
      };

      await helpers.upsertClasses(db, [record]);
      final updated = Map<String, dynamic>.from(record);
      updated['title'] = 'New Title';
      await helpers.upsertClasses(db, [updated]);

      final rows = await db.query(DbTables.classes, where: 'id = ?', whereArgs: ['class-001']);
      expect(rows.length, 1);
      expect(rows.first['title'], 'New Title');
    });

    test('upsertClasses handles multiple records in one call', () async {
      final db = await LocalDatabase().database;
      final records = List.generate(3, (i) => <String, dynamic>{
        'id': 'class-00$i',
        'title': 'Class $i',
        'teacher_id': 'teacher-001',
        'teacher_username': 'tuser',
        'teacher_full_name': 'Teacher Name',
        'is_archived': false,
        'is_advisory': false,
        'student_count': 0,
        'grading_period_type': 'quarter',
        'created_at': '2026-04-19T08:00:00',
        'updated_at': '2026-04-19T08:00:00',
      });
      await helpers.upsertClasses(db, records);
      final rows = await db.query(DbTables.classes);
      expect(rows.length, 3);
    });
  });
}
