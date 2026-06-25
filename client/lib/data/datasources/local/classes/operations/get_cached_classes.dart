import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'get_cached_classes_for_user.dart';

Future<List<ClassModel>> getCachedClasses(
  LocalDatabase localDatabase,
  String? teacherId,
) async {
  try {
    final db = await localDatabase.database;

    // v18: teacher_id column removed from classes table
    // If teacherId is provided, delegate to getCachedClassesForUser instead
    if (teacherId != null) {
      return getCachedClassesForUser(localDatabase, teacherId);
    }

    final results = await db.query(
      DbTables.classes,
      where: '${CommonCols.deletedAt} IS NULL',
      orderBy: '${ClassesCols.title} ASC',
    );

    if (results.isEmpty) {
      return [];
    }

    // Recalculate student_count from local participants for each class
    // to ensure accurate counts regardless of cached values
    final models = <ClassModel>[];
    for (final row in results) {
      final classId = row[CommonCols.id] as String;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbTables.classParticipants} WHERE ${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
        [classId],
      );
      final localCount = (countResult.first['count'] as int?) ?? 0;

      final map = Map<String, dynamic>.from(row);
      map[ClassesCols.studentCount] = localCount;
      models.add(ClassModel.fromMap(map));
    }

    return models;
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
