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

  /// Apply ID mappings to database by updating sync_status
  /// For each mapping, updates sync_status = 'synced' in the correct table WHERE local_id = localId
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
        await db.update(
          tableName,
          {'sync_status': 'synced'},
          where: 'local_id = ?',
          whereArgs: [mapping.localId],
        );
      } catch (e) {
        // Log error but continue processing other mappings
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
