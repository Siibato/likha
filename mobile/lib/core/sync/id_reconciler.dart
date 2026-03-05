import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:sqflite/sqflite.dart';

class IdReconciler {
  static const Map<String, String> _entityToTable = {
    'class': 'classes',
    'classEntity': 'classes',
    'assessment': 'assessments',
    'assignment': 'assignments',
    'learning_material': 'learning_materials',
    'assessment_submission': 'assessment_submissions',
    'assignment_submission': 'assignment_submissions',
    'question': 'questions',
    'assessment_questions': 'questions',
    'class_enrollment': 'class_participants',
    'class_enrollments': 'class_participants',
    'adminUser': 'users',
    'admin_user': 'users',
    'user': 'users',
  };

  static const Map<String, List<(String table, String column)>> _foreignKeyMap = {
    'classes': [
      ('assessments', 'class_id'),
      ('assignments', 'class_id'),
      ('learning_materials', 'class_id'),
      ('class_participants', 'class_id'),
    ],
    'assessments': [
      ('questions', 'assessment_id'),
      ('assessment_submissions', 'assessment_id'),
    ],
    'assignments': [
      ('assignment_submissions', 'assignment_id'),
    ],
    'learning_materials': [
      ('material_files', 'material_id'),
    ],
    'users': [
      ('classes', 'teacher_id'),
    ],
    'questions': [],
    'assessment_submissions': [],
    'assignment_submissions': [],
    'class_participants': [],
    'material_files': [],
  };
  static Map<String, String> reconcileIds(
    List<OperationResultModel> results,
  ) {
    final mapping = <String, String>{};

    for (final result in results) {
      if (result.success && result.serverId != null) {
        mapping[result.id] = result.serverId!;
      }
    }

    return mapping;
  }

  static ({
    Map<String, String> idMap,
    List<FailedOperation> failures,
  }) batchReconcile(List<OperationResultModel> results) {
    final idMap = <String, String>{};
    final failures = <FailedOperation>[];

    for (final result in results) {
      if (result.success && result.serverId != null) {
        idMap[result.id] = result.serverId!;
      } else if (!result.success) {
        failures.add(FailedOperation(
          id: result.id,
          entityType: result.entityType,
          operation: result.operation,
          error: result.error ?? 'Unknown error',
        ));
      }
    }

    return (idMap: idMap, failures: failures);
  }

  /// Check if reconciliation is needed (has unmapped local IDs)
  static bool needsReconciliation(
    Map<String, String> idMap,
    List<String> localIds,
  ) {
    return localIds.any((id) => !idMap.containsKey(id));
  }

  static List<String> getUnmappedIds(
    Map<String, String> idMap,
    List<String> localIds,
  ) {
    return localIds.where((id) => !idMap.containsKey(id)).toList();
  }

  static Future<void> applyToDatabase(
    Database db,
    List<({String entityType, String localId, String serverId})> mappings,
  ) async {
    for (final mapping in mappings) {
      final tableName = _entityToTable[mapping.entityType];
      if (tableName == null) {
        continue;
      }

      try {
        // STEP 1: Update main table ID
        await db.update(
          tableName,
          {
            'id': mapping.serverId,
            'sync_status': 'synced',
          },
          where: 'id = ?',
          whereArgs: [mapping.localId],
        );

        // STEP 2: Update all foreign key references in child tables
        final fks = _foreignKeyMap[tableName] ?? [];
        for (final (fkTable, fkColumn) in fks) {
          try {
            await db.update(
              fkTable,
              {fkColumn: mapping.serverId},
              where: '$fkColumn = ?',
              whereArgs: [mapping.localId],
            );
          } catch (_) {
            // Table might not have any records with this FK, continue
          }
        }
      } catch (_) {
        // Critical error updating main table, but continue with other mappings
      }
    }
  }
}

/// Record of a failed operation for error handling
class FailedOperation {
  final String id;
  final String entityType;
  final String operation;
  final String error;

  FailedOperation({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.error,
  });

  @override
  String toString() =>
      'FailedOperation($entityType:$operation -> $id): $error';
}
