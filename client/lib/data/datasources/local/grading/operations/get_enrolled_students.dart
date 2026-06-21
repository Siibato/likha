import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/local_database.dart';

Future<List<Map<String, dynamic>>> getEnrolledStudents(
  LocalDatabase localDatabase,
  String classId, {
  Transaction? txn,
}) async {
  final db = txn ?? await localDatabase.database;
  return db.rawQuery('''
    SELECT u.id, u.first_name, u.last_name
    FROM class_participants cp
    JOIN users u ON u.id = cp.user_id
    WHERE cp.class_id = ? AND cp.removed_at IS NULL
    ORDER BY u.first_name
  ''', [classId]);
}
