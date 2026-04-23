import 'dart:convert';

import 'package:likha/core/database/db_schema.dart';
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

        final classData = {
          CommonCols.id: record['id'],
          ClassesCols.title: record['title'],
          ClassesCols.description: record['description'],
          ClassesCols.teacherId: teacherId,
          ClassesCols.teacherUsername: record['teacher_username'] ?? '',
          ClassesCols.teacherFullName: record['teacher_full_name'] ?? '',
          ClassesCols.isArchived: (record['is_archived'] == true) ? 1 : 0,
          ClassesCols.isAdvisory: (record['is_advisory'] == true) ? 1 : 0,
          ClassesCols.studentCount: record['student_count'] ?? 0,
          ClassesCols.gradeLevel: record['grade_level'],
          ClassesCols.schoolYear: record['school_year'],
          ClassesCols.gradingPeriodType: record['grading_period_type'] ?? 'quarter',
          CommonCols.createdAt: record['created_at'],
          CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 0,
        };
        final existing = await db.query(
          DbTables.classes,
          where: '${CommonCols.id} = ?',
          whereArgs: [record['id']],
          limit: 1,
        );
        if (existing.isEmpty) {
          await db.insert(DbTables.classes, classData);
        } else {
          await db.update(
            DbTables.classes,
            classData,
            where: '${CommonCols.id} = ?',
            whereArgs: [record['id']],
          );
        }
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
        DbTables.classes,
        where: '${ClassesCols.teacherUsername} = ?',
        whereArgs: [''],
      );

      if (classesNeedingTeacher.isEmpty) return;

      _log.warn('Found ${classesNeedingTeacher.length} classes missing teacher info, attempting fallback');

      // Get cached user accounts
      final cachedUsers = await db.query(DbTables.users);

      // Build teacher map: teacher_id -> (username, full_name)
      final teacherMap = <String, Map<String, String>>{};
      for (final user in cachedUsers) {
        final userId = user[CommonCols.id] as String?;
        final username = user[UsersCols.username] as String?;
        final fullName = user[UsersCols.fullName] as String?;
        if (userId != null && username != null && fullName != null) {
          teacherMap[userId] = {
            'username': username,
            'full_name': fullName,
          };
        }
      }

      int updatedCount = 0;
      for (final cls in classesNeedingTeacher) {
        final teacherId = cls[ClassesCols.teacherId] as String?;
        if (teacherId != null && teacherMap.containsKey(teacherId)) {
          final teacherInfo = teacherMap[teacherId]!;
          await db.update(
            DbTables.classes,
            {
              ClassesCols.teacherUsername: teacherInfo['username'],
              ClassesCols.teacherFullName: teacherInfo['full_name'],
            },
            where: '${CommonCols.id} = ?',
            whereArgs: [cls[CommonCols.id]],
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
        DbTables.classParticipants,
        {
          CommonCols.id: e['id'],
          ClassParticipantsCols.classId: e['class_id'],
          ClassParticipantsCols.userId: userId,
          ClassParticipantsCols.joinedAt: e['joined_at'] ?? e['enrolled_at'],
          CommonCols.updatedAt: e['joined_at'] ?? e['enrolled_at'],
          ClassParticipantsCols.removedAt: e['removed_at'],
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 0,
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
        DbTables.users,
        {
          CommonCols.id: record['id'],
          UsersCols.username: record['username'],
          UsersCols.fullName: record['full_name'],
          UsersCols.role: record['role'],
          UsersCols.accountStatus: record['account_status'],
          UsersCols.activatedAt: record['activated_at'],
          CommonCols.createdAt: record['created_at'],
          CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
          CommonCols.deletedAt: record['deleted_at'],
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 0,
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
        CommonCols.id: assessmentId,
        AssessmentsCols.classId: data['class_id'],
        AssessmentsCols.title: data['title'],
        AssessmentsCols.description: data['description'],
        AssessmentsCols.timeLimitMinutes: data['time_limit_minutes'] ?? 0,
        AssessmentsCols.openAt: data['open_at'] ?? DateTime.now().toIso8601String(),
        AssessmentsCols.closeAt: data['close_at'] ?? DateTime.now().toIso8601String(),
        AssessmentsCols.showResultsImmediately: (data['show_results_immediately'] == true) ? 1 : 0,
        AssessmentsCols.resultsReleased: (data['results_released'] == true) ? 1 : 0,
        AssessmentsCols.isPublished: (data['is_published'] == true) ? 1 : 0,
        AssessmentsCols.orderIndex: data['order_index'] ?? 0,
        AssessmentsCols.totalPoints: data['total_points'] ?? 0,
        AssessmentsCols.questionCount: data['question_count'] ?? 0,
        AssessmentsCols.submissionCount: data['submission_count'] ?? 0,
        AssessmentsCols.tosId: data['tos_id'],
        AssessmentsCols.gradingPeriodNumber: data['grading_period_number'],
        AssessmentsCols.component: data['component'],
        CommonCols.createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
        CommonCols.updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
        CommonCols.deletedAt: data['deleted_at'],
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 0,
      };
      // Use update-first pattern to avoid CASCADE DELETE on assessment_submissions
      final updated = await db.update(DbTables.assessments, map, where: '${CommonCols.id} = ?', whereArgs: [assessmentId]);
      if (updated == 0) {
        await db.insert(DbTables.assessments, map);
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
        DbTables.assessmentQuestions,
        {
          CommonCols.id: data['id'],
          AssessmentQuestionsCols.assessmentId: data['assessment_id'],
          AssessmentQuestionsCols.questionType: data['question_type'],
          AssessmentQuestionsCols.questionText: data['question_text'],
          AssessmentQuestionsCols.points: data['points'] ?? 0,
          AssessmentQuestionsCols.orderIndex: data['order_index'] ?? 0,
          AssessmentQuestionsCols.isMultiSelect: (data['is_multi_select'] == true) ? 1 : 0,
          AssessmentQuestionsCols.tosCompetencyId: data['tos_competency_id'],
          AssessmentQuestionsCols.cognitiveLevel: data['cognitive_level'],
          CommonCols.createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
          CommonCols.updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
          CommonCols.deletedAt: data['deleted_at'],
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Upsert nested question choices
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        // Delete stale choices before inserting fresh ones
        await db.delete(DbTables.questionChoices, where: '${QuestionChoicesCols.questionId} = ?', whereArgs: [data['id']]);
        for (final choice in choices) {
          if (choice is! Map<String, dynamic>) continue;
          await db.insert(
            DbTables.questionChoices,
            {
              CommonCols.id: choice['id'],
              QuestionChoicesCols.questionId: data['id'],
              QuestionChoicesCols.choiceText: choice['choice_text'],
              QuestionChoicesCols.isCorrect: (choice['is_correct'] == true) ? 1 : 0,
              QuestionChoicesCols.orderIndex: choice['order_index'] ?? 0,
              CommonCols.cachedAt: DateTime.now().toIso8601String(),
              CommonCols.needsSync: 0,
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
            DbTables.answerKeys,
            {
              CommonCols.id: answer['id'],
              AnswerKeysCols.questionId: data['id'],
              AnswerKeysCols.itemType: answer['item_type'] as String? ?? DbValues.itemTypeCorrectAnswer,
              CommonCols.cachedAt: DateTime.now().toIso8601String(),
              CommonCols.needsSync: 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Upsert acceptable answers for this answer key
          final acceptableAnswers = answer['acceptable_answers'];
          if (acceptableAnswers is List && acceptableAnswers.isNotEmpty) {
            for (final acceptable in acceptableAnswers) {
              if (acceptable is! Map<String, dynamic>) continue;
              await db.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: acceptable['id'],
                  AnswerKeyAcceptableAnswersCols.answerKeyId: answer['id'],
                  AnswerKeyAcceptableAnswersCols.answerText: acceptable['answer_text'],
                  CommonCols.cachedAt: DateTime.now().toIso8601String(),
                  CommonCols.needsSync: 0,
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
            DbTables.answerKeys,
            {
              CommonCols.id: item['id'],
              AnswerKeysCols.questionId: data['id'],
              AnswerKeysCols.itemType: DbValues.itemTypeEnumerationItem,
              CommonCols.cachedAt: DateTime.now().toIso8601String(),
              CommonCols.needsSync: 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          final acceptableAnswers = item['acceptable_answers'];
          if (acceptableAnswers is List && acceptableAnswers.isNotEmpty) {
            for (final acceptable in acceptableAnswers) {
              if (acceptable is! Map<String, dynamic>) continue;
              await db.insert(
                DbTables.answerKeyAcceptableAnswers,
                {
                  CommonCols.id: acceptable['id'],
                  AnswerKeyAcceptableAnswersCols.answerKeyId: item['id'],
                  AnswerKeyAcceptableAnswersCols.answerText: acceptable['answer_text'],
                  CommonCols.cachedAt: DateTime.now().toIso8601String(),
                  CommonCols.needsSync: 0,
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
        CommonCols.id: assignmentId,
        AssignmentsCols.classId: data['class_id'],
        AssignmentsCols.title: data['title'],
        AssignmentsCols.instructions: data['instructions'],
        AssignmentsCols.totalPoints: data['total_points'] ?? 0,
        AssignmentsCols.allowsTextSubmission: (data['allows_text_submission'] == true) ? 1 : 0,
        AssignmentsCols.allowsFileSubmission: (data['allows_file_submission'] == true) ? 1 : 0,
        AssignmentsCols.allowedFileTypes: data['allowed_file_types'],
        AssignmentsCols.maxFileSizeMb: data['max_file_size_mb'],
        AssignmentsCols.dueAt: data['due_at'] ?? '',
        AssignmentsCols.submissionStatus: data['submission_status'],
        AssignmentsCols.submissionId: data['submission_id'],
        AssignmentsCols.score: data['score'],
        AssignmentsCols.isPublished: (data['is_published'] == true) ? 1 : 0,
        AssignmentsCols.submissionCount: data['submission_count'] ?? 0,
        AssignmentsCols.gradedCount: data['graded_count'] ?? 0,
        AssignmentsCols.orderIndex: data['order_index'] ?? 0,
        AssignmentsCols.gradingPeriodNumber: data['grading_period_number'],
        AssignmentsCols.component: data['component'],
        CommonCols.createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
        CommonCols.updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
        CommonCols.deletedAt: data['deleted_at'],
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 0,
      };
      // Use update-first pattern to avoid CASCADE DELETE on assignment_submissions
      final updated = await db.update(DbTables.assignments, map, where: '${CommonCols.id} = ?', whereArgs: [assignmentId]);
      if (updated == 0) {
        await db.insert(DbTables.assignments, map);
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
        DbTables.learningMaterials,
        {
          CommonCols.id: data['id'],
          LearningMaterialsCols.classId: data['class_id'],
          LearningMaterialsCols.title: data['title'],
          LearningMaterialsCols.description: data['description'],
          LearningMaterialsCols.contentText: data['content_text'],
          LearningMaterialsCols.orderIndex: data['order_index'] ?? 0,
          CommonCols.createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
          CommonCols.updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
          CommonCols.deletedAt: data['deleted_at'],
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 0,
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
    int successCount = 0;
    int failedCount = 0;
    int skippedCount = 0;

    _log.log('Upserting ${records.length} assessment submissions...');

    for (final record in records) {
      try {
        final data = record as Map<String, dynamic>;
        final userId = (data['student_id'] ?? data['user_id'])?.toString();
        final submissionId = data['id']?.toString();

        // Skip if user_id is missing (required field)
        if (userId == null || userId.isEmpty) {
          _log.warn('Assessment submission $submissionId has missing user_id, skipping');
          skippedCount++;
          continue;
        }

        await db.insert(
          DbTables.assessmentSubmissions,
          {
            CommonCols.id: data['id'],
            AssessmentSubmissionsCols.assessmentId: data['assessment_id'],
            AssessmentSubmissionsCols.userId: userId,
            AssessmentSubmissionsCols.startedAt: data['started_at'] ?? DateTime.now().toIso8601String(),
            AssessmentSubmissionsCols.submittedAt: data['submitted_at'],
            AssessmentSubmissionsCols.totalPoints: data['total_points'] ?? 0,
            AssessmentSubmissionsCols.earnedPoints: ((data['earned_points'] ?? data['auto_score'] ?? data['final_score'] ?? data['total_points']) as num?)?.toDouble() ?? 0.0,
            CommonCols.createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
            CommonCols.updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
            CommonCols.deletedAt: data['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final answers = data['answers'] as List<dynamic>? ?? [];
        if (answers.isNotEmpty && submissionId != null) {
          await _upsertSubmissionAnswers(db, submissionId, answers);
        }

        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert assessment submission', e);
      }
    }

    _log.upsertSummary('assessment_submissions', successCount);
    if (skippedCount > 0) {
      _log.warn('Skipped $skippedCount submissions (missing user_id)');
    }
    if (failedCount > 0) {
      _log.warn('Failed to upsert $failedCount assessment submissions');
    }
  }

  Future<void> _upsertSubmissionAnswers(
    Database db,
    String submissionId,
    List<dynamic> answers,
  ) async {
    for (final answer in answers) {
      try {
        final answerData = answer as Map<String, dynamic>;
        final answerId = answerData['id']?.toString();
        if (answerId == null) continue;

        await db.insert(
          DbTables.submissionAnswers,
          {
            CommonCols.id: answerId,
            SubmissionAnswersCols.submissionId: submissionId,
            SubmissionAnswersCols.questionId: answerData['question_id'],
            SubmissionAnswersCols.points: (answerData['points_earned'] as num?)?.toDouble() ?? 0.0,
            SubmissionAnswersCols.overriddenBy: answerData['overridden_by'],
            SubmissionAnswersCols.overriddenAt: answerData['overridden_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final items = answerData['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          try {
            final itemData = item as Map<String, dynamic>;
            final itemId = itemData['id']?.toString();
            if (itemId == null) continue;

            await db.insert(
              DbTables.submissionAnswerItems,
              {
                CommonCols.id: itemId,
                SubmissionAnswerItemsCols.submissionAnswerId: answerId,
                SubmissionAnswerItemsCols.choiceId: itemData['choice_id'],
                SubmissionAnswerItemsCols.answerText: itemData['answer_text'],
                SubmissionAnswerItemsCols.isCorrect: (itemData['is_correct'] == true) ? 1 : 0,
                CommonCols.cachedAt: DateTime.now().toIso8601String(),
                CommonCols.needsSync: 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            _log.error('Failed to upsert submission answer item for answer $answerId', e);
          }
        }
      } catch (e) {
        _log.error('Failed to upsert submission answer for submission $submissionId', e);
      }
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
        DbTables.assignmentSubmissions,
        {
          CommonCols.id: data['id'],
          AssignmentSubmissionsCols.assignmentId: data['assignment_id'],
          AssignmentSubmissionsCols.studentId: data['student_id'],
          AssignmentSubmissionsCols.status: data['status'] ?? 'pending',
          AssignmentSubmissionsCols.textContent: data['text_content'],
          AssignmentSubmissionsCols.submittedAt: data['submitted_at'],
          AssignmentSubmissionsCols.points: data['points'] ?? data['score'],
          AssignmentSubmissionsCols.feedback: data['feedback'],
          AssignmentSubmissionsCols.gradedAt: data['graded_at'],
          AssignmentSubmissionsCols.gradedBy: data['graded_by'],
          CommonCols.createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
          CommonCols.updatedAt: data['updated_at'] ?? DateTime.now().toIso8601String(),
          CommonCols.deletedAt: data['deleted_at'],
          CommonCols.cachedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 0,
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
        columns: [SubmissionFilesCols.localPath], where: '${CommonCols.id} = ?', whereArgs: [data['id']]);
    if (existing.isEmpty) {
      await db.insert(table, {
        CommonCols.id: data['id'],
        fkColumn: data[fkColumn],
        SubmissionFilesCols.fileName: data['file_name'],
        SubmissionFilesCols.fileType: data['file_type'],
        SubmissionFilesCols.fileSize: data['file_size'] ?? 0,
        SubmissionFilesCols.localPath: '',
        SubmissionFilesCols.uploadedAt: data['uploaded_at'] ?? DateTime.now().toIso8601String(),
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.update(table, {
        SubmissionFilesCols.fileName: data['file_name'],
        SubmissionFilesCols.fileType: data['file_type'],
        SubmissionFilesCols.fileSize: data['file_size'] ?? 0,
        SubmissionFilesCols.uploadedAt: data['uploaded_at'] ?? DateTime.now().toIso8601String(),
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
      }, where: '${CommonCols.id} = ?', whereArgs: [data['id']]);
    }
  }

  /// NEW: Upsert material files metadata (no binary data)
  Future<void> upsertMaterialFiles(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      await _preserveLocalPathUpsert(db, DbTables.materialFiles, MaterialFilesCols.materialId, record as Map<String, dynamic>);
    }
  }

  /// NEW: Upsert submission files metadata (no binary data)
  Future<void> upsertSubmissionFiles(
    Database db,
    List<dynamic> records,
  ) async {
    for (final record in records) {
      await _preserveLocalPathUpsert(db, DbTables.submissionFiles, SubmissionFilesCols.submissionId, record as Map<String, dynamic>);
    }
  }

  /// Upsert grade component configurations
  Future<void> upsertGradeConfigs(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        await db.insert(
          DbTables.gradeRecord,
          {
            CommonCols.id: record['id'],
            GradeRecordCols.classId: record['class_id'],
            GradeRecordCols.gradingPeriodNumber: (record['grading_period_number'] as num?)?.toInt(),
            GradeRecordCols.wwWeight: (record['ww_weight'] as num).toDouble(),
            GradeRecordCols.ptWeight: (record['pt_weight'] as num).toDouble(),
            GradeRecordCols.qaWeight: (record['qa_weight'] as num).toDouble(),
            CommonCols.createdAt: record['created_at'],
            CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
            CommonCols.deletedAt: record['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert grade config', e);
      }
    }

    _log.upsertSummary('grade_record', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert grade configs', failedCount);
    }
  }

  /// Upsert grade items
  Future<void> upsertGradeItems(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        await db.insert(
          DbTables.gradeItems,
          {
            CommonCols.id: record['id'],
            GradeItemsCols.classId: record['class_id'],
            GradeItemsCols.title: record['title'],
            GradeItemsCols.component: record['component'],
            GradeItemsCols.gradingPeriodNumber: (record['grading_period_number'] as num?)?.toInt(),
            GradeItemsCols.totalPoints: (record['total_points'] as num).toDouble(),
            GradeItemsCols.sourceType: record['source_type'] ?? 'manual',
            GradeItemsCols.sourceId: record['source_id'],
            GradeItemsCols.orderIndex: (record['order_index'] as num?)?.toInt() ?? 0,
            CommonCols.createdAt: record['created_at'],
            CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
            CommonCols.deletedAt: record['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert grade item', e);
      }
    }

    _log.upsertSummary('grade_items', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert grade items', failedCount);
    }
  }

  /// Upsert grade scores
  Future<void> upsertGradeScores(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;
    int preservedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        final id = record['id'] as String;

        // Check if local has a pending override that should take precedence
        final existing = await db.query(
          DbTables.gradeScores,
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );

        if (existing.isNotEmpty) {
          final localOverride = existing.first[GradeScoresCols.overrideScore];
          final localNeedsSync = existing.first[CommonCols.needsSync] as int?;

          // If local has a pending override AND server score is auto-populated,
          // update base score but preserve local override
          if (localOverride != null &&
              localNeedsSync == 1 &&
              record['is_auto_populated'] == true) {
            await db.update(
              DbTables.gradeScores,
              {
                GradeScoresCols.score: record['score'] != null
                    ? (record['score'] as num).toDouble()
                    : null,
                GradeScoresCols.isAutoPopulated: 1,
                CommonCols.cachedAt: DateTime.now().toIso8601String(),
                // DO NOT overwrite override_score or needsSync
              },
              where: '${CommonCols.id} = ?',
              whereArgs: [id],
            );
            preservedCount++;
            successCount++;
            continue;
          }
        }

        // Normal upsert (no conflict)
        await db.insert(
          DbTables.gradeScores,
          {
            CommonCols.id: id,
            GradeScoresCols.gradeItemId: record['grade_item_id'],
            GradeScoresCols.studentId: record['student_id'],
            GradeScoresCols.score: record['score'] != null
                ? (record['score'] as num).toDouble()
                : null,
            GradeScoresCols.isAutoPopulated:
                (record['is_auto_populated'] == true) ? 1 : 0,
            GradeScoresCols.overrideScore: record['override_score'] != null
                ? (record['override_score'] as num).toDouble()
                : null,
            CommonCols.createdAt: record['created_at'],
            CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
            CommonCols.deletedAt: record['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert grade score', e);
      }
    }

    _log.upsertSummary('grade_scores', successCount);
    if (preservedCount > 0) {
      _log.log('Preserved $preservedCount local score overrides during sync');
    }
    if (failedCount > 0) {
      _log.warn('Failed to upsert grade scores', failedCount);
    }
  }

  /// Upsert quarterly grades
  Future<void> upsertQuarterlyGrades(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        await db.insert(
          DbTables.periodGrades,
          {
            CommonCols.id: record['id'],
            PeriodGradesCols.classId: record['class_id'],
            PeriodGradesCols.studentId: record['student_id'],
            PeriodGradesCols.gradingPeriodNumber: (record['grading_period_number'] as num?)?.toInt(),
            PeriodGradesCols.initialGrade: record['initial_grade'] != null ? (record['initial_grade'] as num).toDouble() : null,
            PeriodGradesCols.transmutedGrade: record['transmuted_grade'] != null ? (record['transmuted_grade'] as num).toInt() : null,
            PeriodGradesCols.isLocked: (record['is_locked'] == true) ? 1 : 0,
            PeriodGradesCols.computedAt: record['computed_at'],
            CommonCols.createdAt: record['created_at'],
            CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
            CommonCols.deletedAt: record['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert period grade', e);
      }
    }

    _log.upsertSummary('period_grades', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert period grades', failedCount);
    }
  }

  /// Upsert table_of_specifications
  Future<void> upsertTableOfSpecifications(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        await db.insert(
          DbTables.tableOfSpecifications,
          {
            CommonCols.id: record['id'],
            TosCols.classId: record['class_id'],
            TosCols.gradingPeriodNumber: (record['grading_period_number'] as num?)?.toInt(),
            TosCols.title: record['title'],
            TosCols.classificationMode: record['classification_mode'],
            TosCols.totalItems: (record['total_items'] as num).toInt(),
            TosCols.timeUnit: record['time_unit'] ?? 'days',
            TosCols.easyPercentage: (record['easy_percentage'] as num?)?.toDouble() ?? 50.0,
            TosCols.mediumPercentage: (record['medium_percentage'] as num?)?.toDouble() ?? 30.0,
            TosCols.hardPercentage: (record['hard_percentage'] as num?)?.toDouble() ?? 20.0,
            CommonCols.createdAt: record['created_at'],
            CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
            CommonCols.deletedAt: record['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert table_of_specifications', e);
      }
    }

    _log.upsertSummary('table_of_specifications', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert table_of_specifications', failedCount);
    }
  }

  /// Upsert tos_competencies
  Future<void> upsertTosCompetencies(
    Database db,
    List<dynamic> records,
  ) async {
    int successCount = 0;
    int failedCount = 0;

    for (final record in records) {
      try {
        if (record is! Map<String, dynamic>) continue;

        await db.insert(
          DbTables.tosCompetencies,
          {
            CommonCols.id: record['id'],
            TosCompetenciesCols.tosId: record['tos_id'],
            TosCompetenciesCols.competencyCode: record['competency_code'],
            TosCompetenciesCols.competencyText: record['competency_text'],
            TosCompetenciesCols.timeUnitsTaught: (record['time_units_taught'] as num?)?.toInt(),
            TosCompetenciesCols.orderIndex: (record['order_index'] as num?)?.toInt() ?? 0,
            TosCompetenciesCols.easyCount: (record['easy_count'] as num?)?.toInt(),
            TosCompetenciesCols.mediumCount: (record['medium_count'] as num?)?.toInt(),
            TosCompetenciesCols.hardCount: (record['hard_count'] as num?)?.toInt(),
            TosCompetenciesCols.rememberingCount: (record['remembering_count'] as num?)?.toInt(),
            TosCompetenciesCols.understandingCount: (record['understanding_count'] as num?)?.toInt(),
            TosCompetenciesCols.applyingCount: (record['applying_count'] as num?)?.toInt(),
            TosCompetenciesCols.analyzingCount: (record['analyzing_count'] as num?)?.toInt(),
            TosCompetenciesCols.evaluatingCount: (record['evaluating_count'] as num?)?.toInt(),
            TosCompetenciesCols.creatingCount: (record['creating_count'] as num?)?.toInt(),
            CommonCols.createdAt: record['created_at'],
            CommonCols.updatedAt: record['updated_at'] ?? record['created_at'],
            CommonCols.deletedAt: record['deleted_at'],
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.needsSync: 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        successCount++;
      } catch (e) {
        failedCount++;
        _log.error('Failed to upsert tos_competency', e);
      }
    }

    _log.upsertSummary('tos_competencies', successCount);
    if (failedCount > 0) {
      _log.warn('Failed to upsert tos_competencies', failedCount);
    }
  }

  /// Save sync token (last_sync_at) to sync_metadata
  Future<void> saveSyncToken(Database db, String syncToken) async {
    await db.insert(
      DbTables.syncMetadata,
      {SyncMetadataCols.key: DbValues.metaLastSyncAt, SyncMetadataCols.value: syncToken},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save sync expiry timestamp to sync_metadata
  Future<void> saveSyncExpiry(Database db, String expiryAt) async {
    await db.insert(
      DbTables.syncMetadata,
      {SyncMetadataCols.key: DbValues.metaDataExpiryAt, SyncMetadataCols.value: expiryAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert current logged-in user
  Future<void> upsertCurrentUser(Database db, Map<String, dynamic> userData) async {
    await db.insert(
      DbTables.users,
      {
        CommonCols.id: userData['id'],
        UsersCols.username: userData['username'],
        UsersCols.fullName: userData['full_name'],
        UsersCols.role: userData['role'],
        UsersCols.accountStatus: userData['account_status'],
        UsersCols.activatedAt: userData['activated_at'],
        CommonCols.createdAt: userData['created_at'],
        CommonCols.updatedAt: userData['updated_at'] ?? userData['created_at'],
        CommonCols.deletedAt: userData['deleted_at'],
        CommonCols.cachedAt: DateTime.now().toIso8601String(),
        CommonCols.needsSync: 0,
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
            DbTables.studentResultsCache,
            {
              StudentResultsCacheCols.submissionId: submissionId,
              StudentResultsCacheCols.resultsJson: jsonEncode(data),
              CommonCols.cachedAt: now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (e) {
          _log.warn('Failed to cache student result: $e');
        }
      }
    });
    _log.upsertSummary(DbTables.studentResultsCache, records.length);
  }

  /// Process delta payload: upsert updated, soft-delete removed
  Future<void> processDeltaPayload(
    Database db,
    Map<String, dynamic> deltas,
  ) async {
    final updatedCounts = <String, int>{};
    final deletedCounts = <String, int>{};

    // Handle classes separately (requires mobile-only defaults)
    final classesDeltas = deltas['classes'];
    if (classesDeltas != null) {
      // EntityDeltas has 'updated' and 'deleted' as properties
      final updated = classesDeltas.updated;
      await upsertClasses(db, updated);
      updatedCounts['classes'] = updated.length;

      final deleted = classesDeltas.deleted;
      deletedCounts['classes'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.classes,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle enrollments separately (requires student data lookup)
    final enrollmentDeltas = deltas['enrollments'];
    if (enrollmentDeltas != null) {
      final updated = enrollmentDeltas.updated;
      updatedCounts['enrollments'] = updated.length;
      await upsertParticipants(db, updated, []);

      final deleted = enrollmentDeltas.deleted;
      deletedCounts['enrollments'] = deleted.length;
      for (final id in deleted) {
        await db.update(DbTables.classParticipants,
            {ClassParticipantsCols.removedAt: DateTime.now().toIso8601String()},
            where: '${CommonCols.id} = ?', whereArgs: [id]);
      }
    }

    // Build student map from local cache for submission enrichment
    final cachedUsers = await db.query(DbTables.users);
    final studentMap = <String, dynamic>{};
    for (final u in cachedUsers) {
      studentMap[u['id'] as String] = u;
    }

    // Handle assessments separately (requires explicit field mapping)
    final assessmentDeltas = deltas['assessments'];
    if (assessmentDeltas != null) {
      final updated = assessmentDeltas.updated;
      updatedCounts['assessments'] = updated.length;
      await upsertAssessments(db, updated);

      final deleted = assessmentDeltas.deleted;
      deletedCounts['assessments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.assessments,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle questions separately (preserves cached choices)
    final questionDeltas = deltas['questions'];
    if (questionDeltas != null) {
      final updated = questionDeltas.updated;
      updatedCounts['questions'] = updated.length;
      await upsertQuestions(db, updated);

      final deleted = questionDeltas.deleted;
      deletedCounts['questions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.assessmentQuestions,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle assessment submissions separately (requires student enrichment)
    final assessmentSubmissionDeltas = deltas['assessment_submissions'];
    if (assessmentSubmissionDeltas != null) {
      final updated = assessmentSubmissionDeltas.updated;
      updatedCounts['assessment_submissions'] = updated.length;
      await upsertAssessmentSubmissions(db, updated, studentMap);

      final deleted = assessmentSubmissionDeltas.deleted;
      deletedCounts['assessment_submissions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.assessmentSubmissions,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle assignments separately (requires explicit field mapping)
    final assignmentDeltas = deltas['assignments'];
    if (assignmentDeltas != null) {
      final updated = assignmentDeltas.updated;
      updatedCounts['assignments'] = updated.length;
      await upsertAssignments(db, updated);

      final deleted = assignmentDeltas.deleted;
      deletedCounts['assignments'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.assignments,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle assignment submissions separately (requires student enrichment)
    final assignmentSubmissionDeltas = deltas['assignment_submissions'];
    if (assignmentSubmissionDeltas != null) {
      final updated = assignmentSubmissionDeltas.updated;
      updatedCounts['assignment_submissions'] = updated.length;
      await upsertAssignmentSubmissions(db, updated, studentMap);

      final deleted = assignmentSubmissionDeltas.deleted;
      deletedCounts['assignment_submissions'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.assignmentSubmissions,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle learning materials separately (requires explicit field mapping)
    final materialDeltas = deltas['learning_materials'];
    if (materialDeltas != null) {
      final updated = materialDeltas.updated;
      updatedCounts['learning_materials'] = updated.length;
      await upsertLearningMaterials(db, updated);

      final deleted = materialDeltas.deleted;
      deletedCounts['learning_materials'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.learningMaterials,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // NEW: Handle material files delta
    final materialFilesDeltas = deltas['material_files'];
    if (materialFilesDeltas != null) {
      final updated = materialFilesDeltas.updated;
      updatedCounts['material_files'] = updated.length;
      await upsertMaterialFiles(db, updated);

      final deleted = materialFilesDeltas.deleted;
      deletedCounts['material_files'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.materialFiles,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // NEW: Handle submission files delta
    final submissionFilesDeltas = deltas['submission_files'];
    if (submissionFilesDeltas != null) {
      final updated = submissionFilesDeltas.updated;
      updatedCounts['submission_files'] = updated.length;
      await upsertSubmissionFiles(db, updated);

      final deleted = submissionFilesDeltas.deleted;
      deletedCounts['submission_files'] = deleted.length;
      for (final id in deleted) {
        await db.delete(
          DbTables.submissionFiles,
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle grade configs delta
    final gradeConfigsDeltas = deltas['grade_configs'];
    if (gradeConfigsDeltas != null) {
      final updated = gradeConfigsDeltas.updated;
      updatedCounts['grade_configs'] = updated.length;
      await upsertGradeConfigs(db, updated);

      final deleted = gradeConfigsDeltas.deleted;
      deletedCounts['grade_configs'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.gradeRecord,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle grade items delta
    final gradeItemsDeltas = deltas['grade_items'];
    if (gradeItemsDeltas != null) {
      final updated = gradeItemsDeltas.updated;
      updatedCounts['grade_items'] = updated.length;
      await upsertGradeItems(db, updated);

      final deleted = gradeItemsDeltas.deleted;
      deletedCounts['grade_items'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.gradeItems,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle grade scores delta
    final gradeScoresDeltas = deltas['grade_scores'];
    if (gradeScoresDeltas != null) {
      final updated = gradeScoresDeltas.updated;
      updatedCounts['grade_scores'] = updated.length;
      await upsertGradeScores(db, updated);

      final deleted = gradeScoresDeltas.deleted;
      deletedCounts['grade_scores'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.gradeScores,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle period grades delta
    final periodGradesDeltas = deltas['period_grades'];
    if (periodGradesDeltas != null) {
      final updated = periodGradesDeltas.updated;
      updatedCounts['period_grades'] = updated.length;
      await upsertQuarterlyGrades(db, updated);

      final deleted = periodGradesDeltas.deleted;
      deletedCounts['period_grades'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.periodGrades,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle table_of_specifications delta
    final tosDeltas = deltas['table_of_specifications'];
    if (tosDeltas != null) {
      final updated = tosDeltas.updated;
      updatedCounts['table_of_specifications'] = updated.length;
      await upsertTableOfSpecifications(db, updated);

      final deleted = tosDeltas.deleted;
      deletedCounts['table_of_specifications'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.tableOfSpecifications,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    // Handle tos_competencies delta
    final tosCompetenciesDeltas = deltas['tos_competencies'];
    if (tosCompetenciesDeltas != null) {
      final updated = tosCompetenciesDeltas.updated;
      updatedCounts['tos_competencies'] = updated.length;
      await upsertTosCompetencies(db, updated);

      final deleted = tosCompetenciesDeltas.deleted;
      deletedCounts['tos_competencies'] = deleted.length;
      for (final id in deleted) {
        await db.update(
          DbTables.tosCompetencies,
          {CommonCols.deletedAt: DateTime.now().toIso8601String()},
          where: '${CommonCols.id} = ?',
          whereArgs: [id],
        );
      }
    }

    final enrolledStudentsDeltas = deltas['enrolled_students'];
    if (enrolledStudentsDeltas != null) {
      final updated = enrolledStudentsDeltas.updated;
      updatedCounts['enrolled_students'] = updated.length;
      await upsertEnrolledStudents(db, updated);

      // Note: We don't soft-delete users - they are reusable across contexts
      // (current user, enrolled students, search results)
    }

    _log.deltaSync(updatedCounts: updatedCounts, deletedCounts: deletedCounts);
  }
}
