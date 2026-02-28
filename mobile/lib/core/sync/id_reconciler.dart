import 'package:likha/data/models/sync/push_response_model.dart';
import 'package:sqflite/sqflite.dart';

/// Reconciles local IDs with server-generated IDs after sync
///
/// When client creates records offline, it generates temporary local IDs.
/// After syncing, the server assigns permanent IDs which need to be
/// reconciled back to the local records.
class IdReconciler {
  /// Map entity type to database table name
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
    'class_enrollment': 'class_enrollments',
    'class_enrollments': 'class_enrollments',
  };

  /// Map table names to their foreign key references
  /// When a parent table ID changes, update all child tables that reference it
  static const Map<String, List<(String table, String column)>> _foreignKeyMap = {
    'classes': [
      ('assessments', 'class_id'),
      ('assignments', 'class_id'),
      ('learning_materials', 'class_id'),
      ('class_enrollments', 'class_id'),
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
    'questions': [],
    'assessment_submissions': [],
    'assignment_submissions': [],
    'class_enrollments': [],
    'material_files': [],
  };
  /// Map local operation IDs to server-generated IDs
  /// Updates all references and creates mapping records
  static Map<String, String> reconcileIds(
    List<OperationResultModel> results,
  ) {
    final mapping = <String, String>{};

    for (final result in results) {
      if (result.success && result.serverId != null) {
        // Local ID -> Server ID mapping
        mapping[result.id] = result.serverId!;
      }
    }

    return mapping;
  }

  /// Batch reconcile multiple operation results
  /// Separates successes and failures for appropriate handling
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

  /// Get unmapped local IDs that need resolution
  static List<String> getUnmappedIds(
    Map<String, String> idMap,
    List<String> localIds,
  ) {
    return localIds.where((id) => !idMap.containsKey(id)).toList();
  }

  /// Apply ID mappings to database
  /// STEP 1: Update main table ID from local UUID to server ID
  /// STEP 2: Update all foreign key references in child tables
  /// STEP 3: Mark sync_status as synced
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
          } catch (e) {
            // Table might not have any records with this FK, continue
            print('Warning: FK cascade update failed for $fkTable.$fkColumn: $e');
          }
        }
      } catch (e) {
        // Critical error updating main table, but continue with other mappings
        print('Error applying ID mapping for ${mapping.entityType}: $e');
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
