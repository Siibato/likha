import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'get_cached_classes_for_user.dart';

Future<List<ClassModel>> getCachedClassesOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String? teacherId,
) async {
  try {
    final db = await localDatabase.database;

    // v18: teacher_id column removed from classes table
    // If teacherId is provided, delegate to getCachedClassesForUser instead
    if (teacherId != null) {
      return getCachedClassesForUserOp(localDatabase, enc, teacherId);
    }

    final results = await db.query(
      DbTables.classes,
      where: '${CommonCols.deletedAt} IS NULL',
      orderBy: '${ClassesCols.title} ASC',
    );

    if (results.isEmpty) {
      return [];
    }

    final models = results.map((r) => ClassModel.fromMap(_decryptClassRow(enc, r))).toList();
    return models;
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}

Map<String, dynamic> _decryptClassRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m['teacher_full_name'] = enc.decryptField(row['teacher_full_name'] as String?);
  m['teacher_username'] = enc.decryptField(row['teacher_username'] as String?);
  return m;
}
