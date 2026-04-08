/// Centralized database schema constants.
/// All table names, column names, and domain value strings used in sqflite
/// queries should be referenced from this file instead of raw string literals.
library db_schema;

// ─── Table names ──────────────────────────────────────────────────────────────

abstract final class DbTables {
  static const String users = 'users';
  static const String refreshTokens = 'refresh_tokens';
  static const String loginAttempts = 'login_attempts';
  static const String activityLogs = 'activity_logs';
  static const String classes = 'classes';
  static const String classParticipants = 'class_participants';
  static const String assessments = 'assessments';
  static const String assessmentQuestions = 'assessment_questions';
  static const String answerKeys = 'answer_keys';
  static const String answerKeyAcceptableAnswers = 'answer_key_acceptable_answers';
  static const String questionChoices = 'question_choices';
  static const String assessmentSubmissions = 'assessment_submissions';
  static const String submissionAnswers = 'submission_answers';
  static const String submissionAnswerItems = 'submission_answer_items';
  static const String assignments = 'assignments';
  static const String assignmentSubmissions = 'assignment_submissions';
  static const String submissionFiles = 'submission_files';
  static const String learningMaterials = 'learning_materials';
  static const String materialFiles = 'material_files';
  static const String syncQueue = 'sync_queue';
  static const String syncMetadata = 'sync_metadata';
  static const String studentResultsCache = 'student_results_cache';
  static const String gradeComponentsConfig = 'grade_components_config';
  static const String gradeItems = 'grade_items';
  static const String gradeScores = 'grade_scores';
  static const String quarterlyGrades = 'quarterly_grades';
  static const String tableOfSpecifications = 'table_of_specifications';
  static const String tosCompetencies = 'tos_competencies';
  static const String melcs = 'melcs';
  static const String assessmentStatisticsCache = 'assessment_statistics_cache';
}

// ─── Common columns ───────────────────────────────────────────────────────────

abstract final class CommonCols {
  static const String id = 'id';
  static const String cachedAt = 'cached_at';
  static const String needsSync = 'needs_sync';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
}

// ─── Per-table column classes ─────────────────────────────────────────────────

abstract final class UsersCols {
  static const String username = 'username';
  static const String fullName = 'full_name';
  static const String role = 'role';
  static const String accountStatus = 'account_status';
  static const String activatedAt = 'activated_at';
}

abstract final class RefreshTokensCols {
  static const String userId = 'user_id';
  static const String token = 'token';
  static const String expiresAt = 'expires_at';
  static const String isRevoked = 'is_revoked';
}

abstract final class LoginAttemptsCols {
  static const String userId = 'user_id';
  static const String ipAddress = 'ip_address';
  static const String attemptedAt = 'attempted_at';
  static const String success = 'success';
}

abstract final class ActivityLogsCols {
  static const String userId = 'user_id';
  static const String action = 'action';
  static const String performedBy = 'performed_by';
  static const String details = 'details';
}

abstract final class ClassesCols {
  static const String title = 'title';
  static const String description = 'description';
  static const String isArchived = 'is_archived';
  static const String teacherId = 'teacher_id';
  static const String teacherUsername = 'teacher_username';
  static const String teacherFullName = 'teacher_full_name';
  static const String studentCount = 'student_count';
  static const String gradeLevel = 'grade_level';
  static const String subjectGroup = 'subject_group';
  static const String schoolYear = 'school_year';
  static const String semester = 'semester';
  static const String isAdvisory = 'is_advisory';
}

abstract final class ClassParticipantsCols {
  static const String classId = 'class_id';
  static const String userId = 'user_id';
  static const String joinedAt = 'joined_at';
  static const String removedAt = 'removed_at';
}

abstract final class AssessmentsCols {
  static const String classId = 'class_id';
  static const String title = 'title';
  static const String description = 'description';
  static const String timeLimitMinutes = 'time_limit_minutes';
  static const String openAt = 'open_at';
  static const String closeAt = 'close_at';
  static const String showResultsImmediately = 'show_results_immediately';
  static const String resultsReleased = 'results_released';
  static const String isPublished = 'is_published';
  static const String orderIndex = 'order_index';
  static const String totalPoints = 'total_points';
  static const String questionCount = 'question_count';
  static const String submissionCount = 'submission_count';
  static const String linkedTosId = 'linked_tos_id';
}

abstract final class AssessmentQuestionsCols {
  static const String assessmentId = 'assessment_id';
  static const String questionType = 'question_type';
  static const String questionText = 'question_text';
  static const String points = 'points';
  static const String orderIndex = 'order_index';
  static const String isMultiSelect = 'is_multi_select';
  static const String tosCompetencyId = 'tos_competency_id';
  static const String cognitiveLevel = 'cognitive_level';
}

abstract final class AnswerKeysCols {
  static const String questionId = 'question_id';
  static const String itemType = 'item_type';
}

abstract final class AnswerKeyAcceptableAnswersCols {
  static const String answerKeyId = 'answer_key_id';
  static const String answerText = 'answer_text';
}

abstract final class QuestionChoicesCols {
  static const String questionId = 'question_id';
  static const String choiceText = 'choice_text';
  static const String isCorrect = 'is_correct';
  static const String orderIndex = 'order_index';
}

abstract final class AssessmentSubmissionsCols {
  static const String assessmentId = 'assessment_id';
  static const String userId = 'user_id';
  static const String startedAt = 'started_at';
  static const String submittedAt = 'submitted_at';
  static const String totalPoints = 'total_points';
  static const String earnedPoints = 'earned_points';
}

abstract final class SubmissionAnswersCols {
  static const String submissionId = 'submission_id';
  static const String questionId = 'question_id';
  static const String points = 'points';
  static const String overriddenBy = 'overridden_by';
  static const String overriddenAt = 'overridden_at';
}

abstract final class SubmissionAnswerItemsCols {
  static const String submissionAnswerId = 'submission_answer_id';
  static const String answerKeyId = 'answer_key_id';
  static const String choiceId = 'choice_id';
  static const String answerText = 'answer_text';
  static const String isCorrect = 'is_correct';
}

abstract final class AssignmentsCols {
  static const String classId = 'class_id';
  static const String title = 'title';
  static const String instructions = 'instructions';
  static const String totalPoints = 'total_points';
  static const String submissionType = 'submission_type';
  static const String allowedFileTypes = 'allowed_file_types';
  static const String maxFileSizeMb = 'max_file_size_mb';
  static const String dueAt = 'due_at';
  static const String isPublished = 'is_published';
  static const String orderIndex = 'order_index';
  static const String submissionCount = 'submission_count';
  static const String gradedCount = 'graded_count';
  static const String submissionStatus = 'submission_status';
  static const String submissionId = 'submission_id';
  static const String score = 'score';
}

abstract final class AssignmentSubmissionsCols {
  static const String assignmentId = 'assignment_id';
  static const String studentId = 'student_id';
  static const String status = 'status';
  static const String textContent = 'text_content';
  static const String submittedAt = 'submitted_at';
  static const String isLate = 'is_late';
  static const String points = 'points';
  static const String feedback = 'feedback';
  static const String gradedAt = 'graded_at';
  static const String gradedBy = 'graded_by';
}

abstract final class SubmissionFilesCols {
  static const String submissionId = 'submission_id';
  static const String fileName = 'file_name';
  static const String fileType = 'file_type';
  static const String fileSize = 'file_size';
  static const String localPath = 'local_path';
  static const String uploadedAt = 'uploaded_at';
}

abstract final class LearningMaterialsCols {
  static const String classId = 'class_id';
  static const String title = 'title';
  static const String description = 'description';
  static const String contentText = 'content_text';
  static const String orderIndex = 'order_index';
}

abstract final class MaterialFilesCols {
  static const String materialId = 'material_id';
  static const String fileName = 'file_name';
  static const String fileType = 'file_type';
  static const String fileSize = 'file_size';
  static const String localPath = 'local_path';
  static const String uploadedAt = 'uploaded_at';
}

abstract final class SyncQueueCols {
  static const String entityType = 'entity_type';
  static const String operation = 'operation';
  static const String payload = 'payload';
  static const String status = 'status';
  static const String retryCount = 'retry_count';
  static const String maxRetries = 'max_retries';
  static const String lastAttemptedAt = 'last_attempted_at';
  static const String completedAt = 'completed_at';
  static const String errorMessage = 'error_message';
}

abstract final class SyncMetadataCols {
  static const String key = 'key';
  static const String value = 'value';
}

abstract final class GradeComponentsConfigCols {
  static const String classId = 'class_id';
  static const String quarter = 'quarter';
  static const String wwWeight = 'ww_weight';
  static const String ptWeight = 'pt_weight';
  static const String qaWeight = 'qa_weight';
}

abstract final class GradeItemsCols {
  static const String classId = 'class_id';
  static const String title = 'title';
  static const String component = 'component';
  static const String quarter = 'quarter';
  static const String totalPoints = 'total_points';
  static const String isDepartmentalExam = 'is_departmental_exam';
  static const String sourceType = 'source_type';
  static const String sourceId = 'source_id';
  static const String orderIndex = 'order_index';
}

abstract final class GradeScoresCols {
  static const String gradeItemId = 'grade_item_id';
  static const String studentId = 'student_id';
  static const String score = 'score';
  static const String isAutoPopulated = 'is_auto_populated';
  static const String overrideScore = 'override_score';
}

abstract final class QuarterlyGradesCols {
  static const String classId = 'class_id';
  static const String studentId = 'student_id';
  static const String quarter = 'quarter';
  static const String wwPercentage = 'ww_percentage';
  static const String ptPercentage = 'pt_percentage';
  static const String qaPercentage = 'qa_percentage';
  static const String wwWeighted = 'ww_weighted';
  static const String ptWeighted = 'pt_weighted';
  static const String qaWeighted = 'qa_weighted';
  static const String initialGrade = 'initial_grade';
  static const String transmutedGrade = 'transmuted_grade';
  static const String isComplete = 'is_complete';
  static const String computedAt = 'computed_at';
}

abstract final class StudentResultsCacheCols {
  static const String submissionId = 'submission_id';
  static const String resultsJson = 'results_json';
}

abstract final class AssessmentStatisticsCacheCols {
  static const String assessmentId = 'assessment_id';
  static const String statisticsJson = 'statistics_json';
}

abstract final class TosCols {
  static const String classId = 'class_id';
  static const String quarter = 'quarter';
  static const String title = 'title';
  static const String classificationMode = 'classification_mode';
  static const String totalItems = 'total_items';
  static const String timeUnit = 'time_unit';
  static const String easyPercentage = 'easy_percentage';
  static const String mediumPercentage = 'medium_percentage';
  static const String hardPercentage = 'hard_percentage';
}

abstract final class TosCompetenciesCols {
  static const String tosId = 'tos_id';
  static const String competencyCode = 'competency_code';
  static const String competencyText = 'competency_text';
  static const String daysTaught = 'days_taught';
  static const String orderIndex = 'order_index';
  static const String easyCount = 'easy_count';
  static const String mediumCount = 'medium_count';
  static const String hardCount = 'hard_count';
}

abstract final class MelcsCols {
  static const String subject = 'subject';
  static const String gradeLevel = 'grade_level';
  static const String quarter = 'quarter';
  static const String competencyCode = 'competency_code';
  static const String competencyText = 'competency_text';
  static const String domain = 'domain';
}

// ─── Domain value strings ─────────────────────────────────────────────────────

abstract final class DbValues {
  // assignment_submissions.status
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusGraded = 'graded';
  static const String statusReturned = 'returned';

  // answer_keys.item_type
  static const String itemTypeCorrectAnswer = 'correct_answer';
  static const String itemTypeEnumerationItem = 'enumeration_item';

  // sync_metadata keys
  static const String metaLastSyncAt = 'last_sync_at';
  static const String metaDataExpiryAt = 'data_expiry_at';
  static const String metaDeviceId = 'device_id';

  // grade_items.component
  static const String componentWrittenWork = 'written_work';
  static const String componentPerformanceTask = 'performance_task';
  static const String componentQuarterlyAssessment = 'quarterly_assessment';

  // grade_items.source_type
  static const String sourceManual = 'manual';
  static const String sourceAssessment = 'assessment';
  static const String sourceAssignment = 'assignment';
}
