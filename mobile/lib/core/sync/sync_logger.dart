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
