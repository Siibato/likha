import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized sync logging module. Reads SYNC_LOGGING_ENABLED from .env.
/// All methods are no-ops when disabled. warn() and error() always log.
class SyncLogger {
  final bool _enabled;

  SyncLogger() : _enabled = _resolveEnabled();

  static bool _resolveEnabled() {
    final raw = dotenv.env['SYNC_LOGGING_ENABLED']?.toLowerCase().trim();
    return raw == 'true' || raw == '1';
  }

  void fullSyncStart(int totalClasses, int totalBatches) {
    if (!_enabled) return;
    debugPrint('[SYNC] ════ FULL SYNC START ════ classes=$totalClasses batches=$totalBatches');
  }

  void baseResponse({required int classes, required int enrollments, required int students}) {
    if (!_enabled) return;
    debugPrint('[SYNC] Phase 1 (base): classes=$classes enrollments=$enrollments students=$students');
  }

  void studentsPerClass(Map<String, dynamic> classData, int studentCount) {
    if (!_enabled) return;
    final id = classData['id'] ?? '?';
    final title = classData['title'] ?? 'Untitled';
    debugPrint('[SYNC]   Class "$title" ($id): $studentCount students');
  }

  void batchStart(int batchIndex, int totalBatches, List<String> classIds) {
    if (!_enabled) return;
    debugPrint('[SYNC] ── Batch ${batchIndex + 1}/$totalBatches | classes=${classIds.join(", ")}');
  }

  void batchReceived(int batchIndex, int totalBatches, Map<String, int> counts) {
    if (!_enabled) return;
    final summary = counts.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    debugPrint('[SYNC] Batch ${batchIndex + 1}/$totalBatches received: $summary');
  }

  void questionsPerAssessment(String title, String assessmentId, int count) {
    if (!_enabled) return;
    debugPrint('[SYNC]   Assessment "$title" ($assessmentId): $count questions');
  }

  void upsertSummary(String entity, int count) {
    if (!_enabled) return;
    debugPrint('[SYNC] Upserting $entity: $count records');
  }

  void upsertRecord(String entity, String id) {
    if (!_enabled) return;
    debugPrint('[SYNC]   $entity id=$id');
  }

  void outboundSync({required int uploadOps, required int regularOps}) {
    if (!_enabled) return;
    debugPrint('[SYNC] Outbound: uploadOps=$uploadOps regularOps=$regularOps');
  }

  void pushStarting({
    required int uploadOpsCount,
    required int regularOpsCount,
    required Map<String, int> operationsByType,
  }) {
    if (!_enabled) return;
    final opTypes = operationsByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    debugPrint('[SYNC] ══ PUSH SYNC START ══ uploadOps=$uploadOpsCount regularOps=$regularOpsCount [$opTypes]');
  }

  void pushResults({
    required Map<String, int> successByType,
    required Map<String, int> failedByType,
    required Map<String, int> idMappingsByType,
    required int totalDuration,
  }) {
    if (!_enabled) return;
    final success = successByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    final failed = failedByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    final mapped = idMappingsByType.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');

    debugPrint('[SYNC] Push results: success[$success] failed[$failed] mapped_ids[$mapped] duration=${totalDuration}ms');
  }

  void pushOperationResult({
    required String entityType,
    required String operation,
    required String opId,
    required bool success,
    required String? serverId,
    required String? error,
  }) {
    if (!_enabled) return;
    if (success) {
      debugPrint('[SYNC]   ✓ $entityType $operation (op_id: ${opId.substring(0, 8)}, server_id: ${serverId?.substring(0, 8) ?? "none"})');
    } else {
      debugPrint('[SYNC]   ✗ $entityType $operation (op_id: ${opId.substring(0, 8)}) | error: $error');
    }
  }

  void pushReconciliation({
    required Map<String, int> reconciliedIds,
    required String? nestedIdMapping,
  }) {
    if (!_enabled) return;
    final reconciled = reconciliedIds.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    if (reconciled.isNotEmpty) {
      debugPrint('[SYNC] Push reconciliation: ID mappings applied [$reconciled]');
    }
    if (nestedIdMapping != null && nestedIdMapping.isNotEmpty) {
      debugPrint('[SYNC]   Nested IDs: $nestedIdMapping');
    }
  }

  void deltaSync({
    required Map<String, int> updatedCounts,
    required Map<String, int> deletedCounts,
  }) {
    if (!_enabled) return;
    final updated = updatedCounts.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    final deleted = deletedCounts.entries.where((e) => e.value > 0).map((e) => '${e.key}=${e.value}').join(', ');
    debugPrint('[SYNC] Delta: updated[$updated] deleted[$deleted]');
  }

  // warn/error always log regardless of _enabled
  void warn(String message, [Object? error]) {
    debugPrint('[SYNC WARN] $message${error != null ? ' | $error' : ''}');
  }

  void error(String message, [Object? error]) {
    debugPrint('[SYNC ERROR] $message${error != null ? ' | $error' : ''}');
  }

  void syncError(String message) {
    debugPrint('[SYNC ERROR] FULL SYNC FAILED: $message');
  }
}
