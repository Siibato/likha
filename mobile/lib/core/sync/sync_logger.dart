import 'package:likha/core/logging/app_logger.dart';

/// Centralized sync logging module. Reads SYNC_LOGGING_ENABLED from .env.
/// All methods are no-ops when disabled. warn() and error() always log.
class SyncLogger extends AppLogger {
  SyncLogger() : super(tag: '[SYNC]', envKey: 'SYNC_LOGGING_ENABLED');

  void fullSyncStart(int totalClasses, int totalBatches) {
    log('════ FULL SYNC START ════ classes=$totalClasses batches=$totalBatches');
  }

  void baseResponse({required int classes, required int enrollments, required int students}) {
    log('Phase 1 (base): classes=$classes enrollments=$enrollments students=$students');
  }

  void studentsPerClass(Map<String, dynamic> classData, int studentCount) {
    final id = classData['id'] ?? '?';
    final title = classData['title'] ?? 'Untitled';
    log('  Class "$title" ($id): $studentCount students');
  }

  void batchStart(int batchIndex, int totalBatches, List<String> classIds) {
    log('── Batch ${batchIndex + 1}/$totalBatches | classes=${classIds.join(", ")}');
  }

  void batchReceived(int batchIndex, int totalBatches, Map<String, int> counts) {
    final summary = counts.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    log('Batch ${batchIndex + 1}/$totalBatches received: $summary');
  }

  void questionsPerAssessment(String title, String assessmentId, int count) {
    log('  Assessment "$title" ($assessmentId): $count questions');
  }

  void upsertSummary(String entity, int count) {
    log('Upserting $entity: $count records');
  }

  void sqliteVerification({
    required int totalClassParticipants,
    required Map<String, int> participantsByClass,
  }) {
    log('✓ SQLite Verification: class_participants table has $totalClassParticipants total rows');
    for (final entry in participantsByClass.entries) {
      log('  class_id ${entry.key.substring(0, 8)}: ${entry.value} students');
    }
  }

  void upsertRecord(String entity, String id) {
    log('  $entity id=$id');
  }

  void outboundSync({required int uploadOps, required int regularOps}) {
    log('Outbound: uploadOps=$uploadOps regularOps=$regularOps');
  }

  void pushStarting({
    required int uploadOpsCount,
    required int regularOpsCount,
    required Map<String, int> operationsByType,
  }) {
    final opTypes = operationsByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    log('══ PUSH SYNC START ══ uploadOps=$uploadOpsCount regularOps=$regularOpsCount [$opTypes]');
  }

  void pushResults({
    required Map<String, int> successByType,
    required Map<String, int> failedByType,
    required Map<String, int> idMappingsByType,
    required int totalDuration,
  }) {
    final success = successByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    final failed = failedByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    final mapped = idMappingsByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');

    log('Push results: success[$success] failed[$failed] mapped_ids[$mapped] duration=${totalDuration}ms');
  }

  void pushOperationResult({
    required String entityType,
    required String operation,
    required String opId,
    required bool success,
    required String? serverId,
    required String? error,
  }) {
    if (success) {
      log('  ✓ $entityType $operation (op_id: ${opId.substring(0, 8)}, server_id: ${serverId?.substring(0, 8) ?? "none"})');
    } else {
      log('  ✗ $entityType $operation (op_id: ${opId.substring(0, 8)}) | error: $error');
    }
  }

  void deltaSync({
    required Map<String, int> updatedCounts,
    required Map<String, int> deletedCounts,
  }) {
    final updated = updatedCounts.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    final deleted = deletedCounts.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    log('Delta: updated[$updated] deleted[$deleted]');
  }

  void assessmentDetailLoad(String assessmentId, {required bool cached, required int questionCount}) {
    final source = cached ? 'CACHE' : 'SERVER';
    log('[DETAIL] Load assessment_id=${assessmentId.substring(0, 8)} from $source: $questionCount questions');
  }

  void assessmentDetailFetch(String assessmentId, {required bool online}) {
    if (online) {
      log('[DETAIL] shouldRefetch=true, fetching from server for assessment_id=${assessmentId.substring(0, 8)}');
    } else {
      log('[DETAIL] shouldRefetch=false, returning cached data for assessment_id=${assessmentId.substring(0, 8)}');
    }
  }

  void assessmentDetailResponse(String assessmentId, int questionCount) {
    log('[DETAIL] Server response for assessment_id=${assessmentId.substring(0, 8)}: $questionCount questions in payload');
  }

  void assessmentDetailBackgroundFetch(String assessmentId, {required bool changed}) {
    final status = changed ? 'CHANGED' : 'UNCHANGED';
    log('[DETAIL] Background fetch for assessment_id=${assessmentId.substring(0, 8)}: $status');
  }

  void syncError(String message) {
    error('FULL SYNC FAILED: $message');
  }
}
