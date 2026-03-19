import 'dart:convert';

import 'package:likha/core/sync/sync_logger.dart';
import 'package:sqflite/sqflite.dart';

class SyncUpsertHelpers {
  final SyncLogger _log;

  SyncUpsertHelpers(this._log);

  Future<void> upsertClasses(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        final teacherId = record['teacher_id'] ?? '';
        if (teacherId.isEmpty) {
          _log.warn('Class ${record['id']} has missing teacher_id', record);
        }

        await db.insert(
          'classes',
          {
            'id': record['id'],
            'title': record['title'],
            'description': record['description'],
            'teacher_id': teacherId,
            'teacher_username': record['teacher_username'] ?? '',
            'teacher_full_name': record['teacher_full_name'] ?? '',
            'is_archived': (record['is_archived'] == true) ? 1 : 0,
            'student_count': record['student_count'] ?? 0,
            'created_at': record['created_at'],
            'updated_at': record['updated_at'] ?? record['created_at'],
            'cached_at': DateTime.now().toIso8601String(),
            'needs_sync': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert class', e);
      }
    }

    _log.upsertSummary('classes', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert classes', failedCount);
    }

    await populateTeacherInfoFromAccounts(db);
  }

  Future<void> populateTeacherInfoFromAccounts(Database db) async {
    try {
      final classesNeedingTeacher = await db.query(
        'classes',
        where: 'teacher_username = ?',
        whereArgs: [''],
      );

      if (classesNeedingTeacher.isEmpty) return;

      _log.warn('Found ${classesNeedingTeacher.length} classes missing teacher info, attempting fallback');

      // Get cached user accounts
      final cachedUsers = await db.query('users');

      // Build teacher map: teacher_id -> (username, full_name)
      final teacherMap = <String, Map<String, String>>{};
      for (final user in cachedUsers) {
        final userId = user['id'] as String?;
        final username = user['username'] as String?;
        final fullName = user['full_name'] as String?;
        if (userId != null && username != null && fullName != null) {
          teacherMap[userId] = {
            'username': username,
            'full_name': fullName,
          };
        }
      }

      int updatedCount = 0;
      for (final cls in classesNeedingTeacher) {
        final teacherId = cls['teacher_id'] as String?;
        if (teacherId != null && teacherMap.containsKey(teacherId)) {
          final teacherInfo = teacherMap[teacherId]!;
          await db.update(
            'classes',
            {
              'teacher_username': teacherInfo['username'],
              'teacher_full_name': teacherInfo['full_name'],
            },
            where: 'id = ?',
            whereArgs: [cls['id']],
          );
          updatedCount++;
        }
      }
      _log.warn('Fallback populated $updatedCount/${classesNeedingTeacher.length} class teacher info');
    } catch (e, st) {
      _log.error('Error populating teacher info from accounts', '$e\n$st');
    }
  }

  Future<void> upsertParticipants(
    Database db,
    List<dynamic> participants,
    List<dynamic> participantUsers,
  ) async {
    // Build lookup map: user_id -> student data
    final studentMap = <String, Map<String, dynamic>>{};
    for (final s in participantUsers) {
      if (s is! Map<String, dynamic>) continue;
      final id = s['id']?.toString();
      if (id != null && id.isNotEmpty) {
        studentMap[id] = s;
      }
    }

    for (final participant in participants) {
      if (participant is! Map<String, dynamic>) continue;
      final e = participant;
      // Accept both user_id (new) and student_id (old) for backward compat
      final userId = (e['user_id'] ?? e['student_id'])?.toString();
      if (userId == null || userId.isEmpty) continue;

      await db.insert(
        'class_participants',
        {
          'id': e['id'],
          'class_id': e['class_id'],
          'user_id': userId,
          'joined_at': e['joined_at'] ?? e['enrolled_at'],
          'updated_at': e['joined_at'] ?? e['enrolled_at'],
          'removed_at': e['removed_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> recalculateClassStudentCounts(Database db) async {
    try {
      await db.rawUpdate('''
        UPDATE classes
        SET student_count = (
          SELECT COUNT(*)
          FROM class_participants
          WHERE class_id = classes.id AND removed_at IS NULL
        )
        WHERE deleted_at IS NULL
      ''');
    } catch (e) {
      _log.error('Failed to recalculate class student counts', e);
    }
  }

  /// This distinguishes enrolled students from search-cached students
  Future<void> upsertEnrolledStudents(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      if (record is! Map<String, dynamic>) continue;
      // Only insert columns that exist in the users table
      await db.insert(
        'users',
        {
          'id': record['id'],
          'username': record['username'],
          'full_name': record['full_name'],
          'role': record['role'],
          'account_status': record['account_status'],
          'activated_at': record['activated_at'],
          'created_at': record['created_at'],
          'updated_at': record['updated_at'] ?? record['created_at'],
          'deleted_at': record['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assessments with proper field mapping
  Future<void> upsertAssessments(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final assessmentId = data['id'];
      final map = {
        'id': assessmentId,
        'class_id': data['class_id'],
        'title': data['title'],
        'description': data['description'],
        'time_limit_minutes': data['time_limit_minutes'] ?? 0,
        'open_at': data['open_at'] ?? DateTime.now().toIso8601String(),
        'close_at': data['close_at'] ?? DateTime.now().toIso8601String(),
        'show_results_immediately': (data['show_results_immediately'] == true) ? 1 : 0,
        'results_released': (data['results_released'] == true) ? 1 : 0,
        'is_published': (data['is_published'] == true) ? 1 : 0,
        'order_index': data['order_index'] ?? 0,
        'total_points': data['total_points'] ?? 0,
        'question_count': data['question_count'] ?? 0,
        'submission_count': data['submission_count'] ?? 0,
        'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
        'deleted_at': data['deleted_at'],
        'cached_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      };
      // Use update-first pattern to avoid CASCADE DELETE on assessment_submissions
      final updated = await db.update('assessments', map, where: 'id = ?', whereArgs: [assessmentId]);
      if (updated == 0) {
        await db.insert('assessments', map);
      }
    }
  }

  /// Explicit upsert handler for questions with proper field mapping
  Future<void> upsertQuestions(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;

      await db.insert(
        'assessment_questions',
        {
          'id': data['id'],
          'assessment_id': data['assessment_id'],
          'question_type': data['question_type'],
          'question_text': data['question_text'],
          'points': data['points'] ?? 0,
          'order_index': data['order_index'] ?? 0,
          'is_multi_select': (data['is_multi_select'] == true) ? 1 : 0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Upsert nested question choices
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        // Delete stale choices before inserting fresh ones
        await db.delete('question_choices', where: 'question_id = ?', whereArgs: [data['id']]);
        for (final choice in choices) {
          if (choice is! Map<String, dynamic>) continue;
          await db.insert(
            'question_choices',
            {
              'id': choice['id'],
              'question_id': data['id'],
              'choice_text': choice['choice_text'],
              'is_correct': (choice['is_correct'] == true) ? 1 : 0,
              'order_index': choice['order_index'] ?? 0,
              'cached_at': DateTime.now().toIso8601String(),
              'needs_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Upsert nested answer keys
      final correctAnswers = data['correct_answers'];
      if (correctAnswers is List && correctAnswers.isNotEmpty) {
        for (final answer in correctAnswers) {
          if (answer is! Map<String, dynamic>) continue;
          await db.insert(
            'answer_keys',
            {
              'id': answer['id'],
              'question_id': data['id'],
              'item_type': answer['item_type'] as String? ?? 'correct_answer',
              'cached_at': DateTime.now().toIso8601String(),
              'needs_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Upsert acceptable answers for this answer key
          final acceptableAnswers = answer['acceptable_answers'];
          if (acceptableAnswers is List && acceptableAnswers.isNotEmpty) {
            for (final acceptable in acceptableAnswers) {
              if (acceptable is! Map<String, dynamic>) continue;
              await db.insert(
                'answer_key_acceptable_answers',
                {
                  'id': acceptable['id'],
                  'answer_key_id': answer['id'],
                  'answer_text': acceptable['answer_text'],
                  'cached_at': DateTime.now().toIso8601String(),
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }

      // Upsert enumeration items as answer_keys with item_type = 'enumeration_item'
      final enumerationItems = data['enumeration_items'];
      if (enumerationItems is List && enumerationItems.isNotEmpty) {
        for (final item in enumerationItems) {
          if (item is! Map<String, dynamic>) continue;
          await db.insert(
            'answer_keys',
            {
              'id': item['id'],
              'question_id': data['id'],
              'item_type': 'enumeration_item',
              'cached_at': DateTime.now().toIso8601String(),
              'needs_sync': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          final acceptableAnswers = item['acceptable_answers'];
          if (acceptableAnswers is List && acceptableAnswers.isNotEmpty) {
            for (final acceptable in acceptableAnswers) {
              if (acceptable is! Map<String, dynamic>) continue;
              await db.insert(
                'answer_key_acceptable_answers',
                {
                  'id': acceptable['id'],
                  'answer_key_id': item['id'],
                  'answer_text': acceptable['answer_text'],
                  'cached_at': DateTime.now().toIso8601String(),
                  'needs_sync': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }
    }
  }

  /// Explicit upsert handler for assignments with proper field mapping
  Future<void> upsertAssignments(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final assignmentId = data['id'];
      final map = {
        'id': assignmentId,
        'class_id': data['class_id'],
        'title': data['title'],
        'instructions': data['instructions'],
        'total_points': data['total_points'] ?? 0,
        'submission_type': data['submission_type'] ?? 'text_only',
        'allowed_file_types': data['allowed_file_types'],
        'max_file_size_mb': data['max_file_size_mb'],
        'due_at': data['due_at'] ?? '',
        'submission_status': data['submission_status'],
        'submission_id': data['submission_id'],
        'score': data['score'],
        'is_published': (data['is_published'] == true) ? 1 : 0,
        'submission_count': data['submission_count'] ?? 0,
        'graded_count': data['graded_count'] ?? 0,
        'order_index': data['order_index'] ?? 0,
        'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
        'deleted_at': data['deleted_at'],
        'cached_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      };
      // Use update-first pattern to avoid CASCADE DELETE on assignment_submissions
      final updated = await db.update('assignments', map, where: 'id = ?', whereArgs: [assignmentId]);
      if (updated == 0) {
        await db.insert('assignments', map);
      }
    }
  }

  /// Explicit upsert handler for learning materials with proper field mapping
  Future<void> upsertLearningMaterials(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      await db.insert(
        'learning_materials',
        {
          'id': data['id'],
          'class_id': data['class_id'],
          'title': data['title'],
          'description': data['description'],
          'content_text': data['content_text'],
          'order_index': data['order_index'] ?? 0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assessment submissions with nested answers
  Future<void> upsertAssessmentSubmissions(
    Database db,
    List<dynamic> records,
    Map<String, dynamic> studentMap,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;
      final userId = (data['student_id'] ?? data['user_id'])?.toString();

      // Skip if user_id is missing (required field)
      if (userId == null || userId.isEmpty) {
        _log.warn('Assessment submission ${data['id']} has missing user_id, skipping');
        continue;
      }

      await db.insert(
        'assessment_submissions',
        {
          'id': data['id'],
          'assessment_id': data['assessment_id'],
          'user_id': userId,
          'started_at': data['started_at'] ?? DateTime.now().toIso8601String(),
          'submitted_at': data['submitted_at'],
          'total_points': data['total_points'] ?? 0,
          'earned_points': ((data['earned_points'] ?? data['auto_score'] ?? data['final_score'] ?? data['total_points']) as num?)?.toDouble() ?? 0.0,
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Explicit upsert handler for assignment submissions with student enrichment
  Future<void> upsertAssignmentSubmissions(
    Database db,
    List<dynamic> records,
    Map<String, dynamic> studentMap,
  ) async {
    for (final record in records) {
      final data = record as Map<String, dynamic>;

      await db.insert(
        'assignment_submissions',
        {
          'id': data['id'],
          'assignment_id': data['assignment_id'],
          'student_id': data['student_id'],
          'status': data['status'] ?? 'pending',
          'text_content': data['text_content'],
          'submitted_at': data['submitted_at'],
          'is_late': (data['is_late'] == true) ? 1 : 0,
          'points': data['score'],
          'feedback': data['feedback'],
          'graded_at': data['graded_at'],
          'graded_by': data['graded_by'],
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
          'deleted_at': data['deleted_at'],
          'cached_at': DateTime.now().toIso8601String(),
          'needs_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _preserveLocalPathUpsert(
    Database db,
    String table,
    String fkColumn,
    Map<String, dynamic> data,
  ) async {
    final existing = await db.query(table,
        columns: ['local_path'], where: 'id = ?', whereArgs: [data['id']]);
    if (existing.isEmpty) {
      await db.insert(table, {
        'id': data['id'],
        fkColumn: data[fkColumn],
        'file_name': data['file_name'],
        'file_type': data['file_type'],
        'file_size': data['file_size'] ?? 0,
        'local_path': '',
        'uploaded_at': data['uploaded_at'] ?? DateTime.now().toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.update(table, {
        'file_name': data['file_name'],
        'file_type': data['file_type'],
        'file_size': data['file_size'] ?? 0,
        'uploaded_at': data['uploaded_at'] ?? DateTime.now().toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [data['id']]);
    }
  }

  /// NEW: Upsert material files metadata (no binary data)
  Future<void> upsertMaterialFiles(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      await _preserveLocalPathUpsert(db, 'material_files', 'material_id', record as Map<String, dynamic>);
    }
  }

  /// NEW: Upsert submission files metadata (no binary data)
  Future<void> upsertSubmissionFiles(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      await _preserveLocalPathUpsert(db, 'submission_files', 'submission_id', record as Map<String, dynamic>);
    }
  }

  /// Save sync token (last_sync_at) to sync_metadata
  Future<void> saveSyncToken(Database db, String syncToken) async {
    await db.insert(
      'sync_metadata',
      {'key': 'last_sync_at', 'value': syncToken},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save sync expiry timestamp to sync_metadata
  Future<void> saveSyncExpiry(Database db, String expiryAt) async {
    await db.insert(
      'sync_metadata',
      {'key': 'data_expiry_at', 'value': expiryAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert current logged-in user
  Future<void> upsertCurrentUser(Database db, Map<String, dynamic> userData) async {
    await db.insert(
      'users',
      {
        'id': userData['id'],
        'username': userData['username'],
        'full_name': userData['full_name'],
        'role': userData['role'],
        'account_status': userData['account_status'],
        'activated_at': userData['activated_at'],
        'created_at': userData['created_at'],
        'updated_at': userData['updated_at'] ?? userData['created_at'],
        'deleted_at': userData['deleted_at'],
        'cached_at': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// DEPRECATED: assessment_statistics_cache table doesn't exist in schema
  /// This method is kept for reference but is never called.
  @Deprecated('Table assessment_statistics_cache does not exist in local_database schema')
  Future<void> upsertStatistics(
    Database db,
    List<dynamic> records,
  ) async {
    _log.warn('upsertStatistics called but table does not exist; skipping');
    // Table doesn't exist - method is a no-op
  }

  /// Upsert student results cache (assessment performance data)
  Future<void> upsertStudentResults(
    Database db,
    List<dynamic> records,
  ) async {
    if (records.isEmpty) return;
    await db.transaction((txn) async {
      for (final result in records) {
        try {
          final data = result as Map<String, dynamic>;
          final submissionId = data['submission_id']?.toString();
          if (submissionId == null || submissionId.isEmpty) {
            _log.warn('Student result missing submission_id, skipping');
            continue;
          }
          final now = DateTime.now().toIso8601String();
          await txn.insert(
            'student_results_cache',
            {
              'submission_id': submissionId,
              'results_json': jsonEncode(data),
              'cached_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (e) {
          _log.warn('Failed to cache student result: $e');
        }
      }
    });
    _log.upsertSummary('student_results_cache', records.length);
  }

  /// Process delta payload: upsert updated, soft-delete removed
  Future<void> processDeltaPayload(
    Database db,
    Map<String, dynamic> deltas,
  ) async {
    final updatedCounts = <String, int>{};
    final deletedCounts = <String, int>{};

    // Handle classes separately (requires mobile-only defaults)
    final classesDeltas = deltas['classes'] as Map<String, dynamic>?;
    if (classesDeltas != null) {
      final updated = classesDeltas['updated'] as List<dynamic>? ?? [];
      await upsertClasses(db, updated);
      updatedCounts['classes'] = updated.length;

      final deleted = classesDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['classes'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'classes',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle enrollments separately (requires student data lookup)
    final enrollmentDeltas = deltas['enrollments'] as Map<String, dynamic>?;
    if (enrollmentDeltas != null) {
      final updated = enrollmentDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['enrollments'] = updated.length;
      await upsertParticipants(db, updated, []);

      final deleted = enrollmentDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['enrollments'] = deleted.length;
      for (final id in deleted) {
        await db.update('class_participants',
            {'removed_at': DateTime.now().toIso8601String()},
            where: 'id = ?', whereArgs: [id as String]);
      }
    }

    // Build student map from local cache for submission enrichment
    final cachedUsers = await db.query('users');
    final studentMap = <String, dynamic>{};
    for (final u in cachedUsers) {
      studentMap[u['id'] as String] = u;
    }

    // Handle assessments separately (requires explicit field mapping)
    final assessmentDeltas = deltas['assessments'] as Map<String, dynamic>?;
    if (assessmentDeltas != null) {
      final updated = assessmentDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assessments'] = updated.length;
      await upsertAssessments(db, updated);

      final deleted = assessmentDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assessments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assessments',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle questions separately (preserves cached choices)
    final questionDeltas = deltas['questions'] as Map<String, dynamic>?;
    if (questionDeltas != null) {
      final updated = questionDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['questions'] = updated.length;
      await upsertQuestions(db, updated);

      final deleted = questionDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['questions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assessment_questions',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle assessment submissions separately (requires student enrichment)
    final assessmentSubmissionDeltas = deltas['assessment_submissions'] as Map<String, dynamic>?;
    if (assessmentSubmissionDeltas != null) {
      final updated = assessmentSubmissionDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assessment_submissions'] = updated.length;
      await upsertAssessmentSubmissions(db, updated, studentMap);

      final deleted = assessmentSubmissionDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assessment_submissions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assessment_submissions',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle assignments separately (requires explicit field mapping)
    final assignmentDeltas = deltas['assignments'] as Map<String, dynamic>?;
    if (assignmentDeltas != null) {
      final updated = assignmentDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assignments'] = updated.length;
      await upsertAssignments(db, updated);

      final deleted = assignmentDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assignments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assignments',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle assignment submissions separately (requires student enrichment)
    final assignmentSubmissionDeltas = deltas['assignment_submissions'] as Map<String, dynamic>?;
    if (assignmentSubmissionDeltas != null) {
      final updated = assignmentSubmissionDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['assignment_submissions'] = updated.length;
      await upsertAssignmentSubmissions(db, updated, studentMap);

      final deleted = assignmentSubmissionDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['assignment_submissions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'assignment_submissions',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // Handle learning materials separately (requires explicit field mapping)
    final materialDeltas = deltas['learning_materials'] as Map<String, dynamic>?;
    if (materialDeltas != null) {
      final updated = materialDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['learning_materials'] = updated.length;
      await upsertLearningMaterials(db, updated);

      final deleted = materialDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['learning_materials'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'learning_materials',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // NEW: Handle material files delta
    final materialFilesDeltas = deltas['material_files'] as Map<String, dynamic>?;
    if (materialFilesDeltas != null) {
      final updated = materialFilesDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['material_files'] = updated.length;
      await upsertMaterialFiles(db, updated);

      final deleted = materialFilesDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['material_files'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          'material_files',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    // NEW: Handle submission files delta
    final submissionFilesDeltas = deltas['submission_files'] as Map<String, dynamic>?;
    if (submissionFilesDeltas != null) {
      final updated = submissionFilesDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['submission_files'] = updated.length;
      await upsertSubmissionFiles(db, updated);

      final deleted = submissionFilesDeltas['deleted'] as List<dynamic>? ?? [];
      deletedCounts['submission_files'] = deleted.length;
      for (final id in deleted) {
        await db.delete(
          'submission_files',
          where: 'id = ?',
          whereArgs: [id as String],
        );
      }
    }

    final enrolledStudentsDeltas = deltas['enrolled_students'] as Map<String, dynamic>?;
    if (enrolledStudentsDeltas != null) {
      final updated = enrolledStudentsDeltas['updated'] as List<dynamic>? ?? [];
      updatedCounts['enrolled_students'] = updated.length;
      await upsertEnrolledStudents(db, updated);

      // Note: We don't soft-delete users - they are reusable across contexts
      // (current user, enrolled students, search results)
    }

    _log.deltaSync(updatedCounts: updatedCounts, deletedCounts: deletedCounts);
  }
}
