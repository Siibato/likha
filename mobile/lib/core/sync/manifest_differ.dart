import 'package:likha/data/models/sync/manifest_response_model.dart';

/// Compares local and server manifests to identify stale records
///
/// Used to determine which records need to be fetched during sync
class ManifestDiffer {
  /// Find tombstones (deleted records) from server manifest
  /// Returns list of {entity_type: '...', id: '...'} for all records marked as deleted
  static List<Map<String, String>> findTombstones(ManifestResponseModel serverManifest) {
    final tombstones = <Map<String, String>>[];

    final entityTypeMappings = [
      ('classes', serverManifest.classes),
      ('enrollments', serverManifest.enrollments),
      ('assessments', serverManifest.assessments),
      ('assessment_questions', serverManifest.assessmentQuestions),
      ('assessment_submissions', serverManifest.assessmentSubmissions),
      ('assignments', serverManifest.assignments),
      ('assignment_submissions', serverManifest.assignmentSubmissions),
      ('learning_materials', serverManifest.learningMaterials),
    ];

    for (final (entityType, entries) in entityTypeMappings) {
      for (final entry in entries) {
        if (entry.deleted) {
          tombstones.add({
            'entity_type': entityType,
            'id': entry.id,
          });
        }
      }
    }

    return tombstones;
  }

  /// Compare local and server manifests
  /// Returns entities that are stale (need to be fetched)
  ///
  /// A record is considered stale if:
  /// - It exists on server but not locally (new)
  /// - Server version is newer than local (updated)
  static Map<String, List<String>> findStaleRecords({
    required ManifestResponseModel serverManifest,
    required Map<String, Map<String, LocalManifestEntry>> localManifest,
  }) {
    final stale = <String, List<String>>{};

    // Check classes
    stale['classes'] = _findStaleIds(
      'classes',
      serverManifest.classes,
      localManifest['classes'] ?? {},
    );

    // Check assessments
    stale['assessments'] = _findStaleIds(
      'assessments',
      serverManifest.assessments,
      localManifest['assessments'] ?? {},
    );

    // Check assignments
    stale['assignments'] = _findStaleIds(
      'assignments',
      serverManifest.assignments,
      localManifest['assignments'] ?? {},
    );

    // Check learning materials
    stale['learning_materials'] = _findStaleIds(
      'learning_materials',
      serverManifest.learningMaterials,
      localManifest['learning_materials'] ?? {},
    );

    // Check assessment questions
    stale['assessment_questions'] = _findStaleIds(
      'assessment_questions',
      serverManifest.assessmentQuestions,
      localManifest['assessment_questions'] ?? {},
    );

    // Check assessment submissions
    stale['assessment_submissions'] = _findStaleIds(
      'assessment_submissions',
      serverManifest.assessmentSubmissions,
      localManifest['assessment_submissions'] ?? {},
    );

    // Check assignment submissions
    stale['assignment_submissions'] = _findStaleIds(
      'assignment_submissions',
      serverManifest.assignmentSubmissions,
      localManifest['assignment_submissions'] ?? {},
    );

    // Check enrollments
    stale['enrollments'] = _findStaleIds(
      'enrollments',
      serverManifest.enrollments,
      localManifest['enrollments'] ?? {},
    );

    return stale;
  }

  /// Find stale record IDs by comparing timestamps
  static List<String> _findStaleIds(
    String entityType,
    List<ManifestEntry> serverEntries,
    Map<String, LocalManifestEntry> localEntries,
  ) {
    final staleIds = <String>[];

    for (final serverEntry in serverEntries) {
      final localEntry = localEntries[serverEntry.id];

      if (localEntry == null) {
        // New record on server
        if (!serverEntry.deleted) {
          staleIds.add(serverEntry.id);
        }
      } else {
        // Record exists locally - check if updated
        final serverTime = DateTime.parse(serverEntry.updatedAt);
        final localTime = DateTime.parse(localEntry.updatedAt);

        if (serverTime.isAfter(localTime)) {
          // Server version is newer
          staleIds.add(serverEntry.id);
        }
      }
    }

    return staleIds;
  }
}

/// Manifest entry for local comparison
class LocalManifestEntry {
  final String id;
  final String updatedAt;
  final bool deleted;

  LocalManifestEntry({
    required this.id,
    required this.updatedAt,
    required this.deleted,
  });
}
