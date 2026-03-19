import 'package:likha/core/constants/api_endpoint.dart';
import 'package:likha/data/models/auth/activity_log_model.dart';
import 'package:likha/data/models/auth/auth_response_model.dart';
import 'package:likha/data/models/auth/check_username_result_model.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart';
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:likha/data/models/learning_materials/learning_material_model.dart';
import 'package:likha/data/models/learning_materials/material_detail_model.dart';
import 'package:likha/data/models/learning_materials/material_file_model.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // ===== Auth Endpoints =====
  static final ApiEndpoint<CheckUsernameResultModel> checkUsername =
      ApiEndpoint.fromModel(
    '/api/v1/auth/check-username',
    CheckUsernameResultModel.fromJson,
  );

  static final ApiEndpoint<AuthResponseModel> activate =
      ApiEndpoint.fromModel(
    '/api/v1/auth/activate',
    AuthResponseModel.fromJson,
  );

  static final ApiEndpoint<AuthResponseModel> login = ApiEndpoint.fromModel(
    '/api/v1/auth/login',
    AuthResponseModel.fromJson,
  );

  static final ApiEndpoint<AuthResponseModel> refresh = ApiEndpoint.fromModel(
    '/api/v1/auth/refresh',
    AuthResponseModel.fromJson,
  );

  static final ApiEndpoint<UserModel> me = ApiEndpoint.fromModel(
    '/api/v1/auth/me',
    UserModel.fromJson,
  );

  static final logout = ApiEndpoint<void>(
    '/api/v1/auth/logout',
    (_) {},
  );

  // ===== Admin Account Endpoints =====
  static final accountsList = ApiEndpoint<List<UserModel>>(
    '/api/v1/auth/accounts',
    (json) => (json['accounts'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static final ApiEndpoint<UserModel> accountsCreate = ApiEndpoint.fromModel(
    '/api/v1/auth/accounts',
    UserModel.fromJson,
  );

  static final ApiEndpoint<UserModel> accountsReset = ApiEndpoint.fromModel(
    '/api/v1/auth/accounts/reset',
    UserModel.fromJson,
  );

  static final ApiEndpoint<UserModel> accountsLock = ApiEndpoint.fromModel(
    '/api/v1/auth/accounts/lock',
    UserModel.fromJson,
  );

  static ApiEndpoint<UserModel> accountUpdate(String userId) =>
      ApiEndpoint.fromModel(
        '/api/v1/auth/accounts/$userId',
        UserModel.fromJson,
      );

  static ApiEndpoint<List<ActivityLogModel>> accountLogs(String userId) =>
      ApiEndpoint(
        '/api/v1/auth/accounts/$userId/logs',
        (json) => (json['logs'] as List<dynamic>)
            .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ===== Class Endpoints =====
  static final classes = ApiEndpoint<List<ClassModel>>(
    '/api/v1/classes',
    (json) => (json['classes'] as List<dynamic>)
        .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static final classesMetadata = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/classes/metadata',
    (json) => json as Map<String, dynamic>,
  );

  static ApiEndpoint<ClassDetailModel> classDetail(String classId) =>
      ApiEndpoint<ClassDetailModel>.fromModel(
        '/api/v1/classes/$classId',
        ClassDetailModel.fromJson,
      );

  static final classCreate = ApiEndpoint<ClassModel>.fromModel(
    '/api/v1/classes',
    ClassModel.fromJson,
  );

  static ApiEndpoint<ClassModel> classUpdate(String classId) =>
      ApiEndpoint<ClassModel>.fromModel(
        '/api/v1/classes/$classId',
        ClassModel.fromJson,
      );

  static ApiEndpoint<ParticipantModel> classStudents(String classId) =>
      ApiEndpoint<ParticipantModel>.fromModel(
        '/api/v1/classes/$classId/students',
        ParticipantModel.fromJson,
      );

  static ApiEndpoint<void> classStudent(String classId, String studentId) =>
      ApiEndpoint(
        '/api/v1/classes/$classId/students/$studentId',
        (_) {},
      );

  static final searchStudents = ApiEndpoint<List<UserModel>>(
    '/api/v1/students/search',
    (json) => (json as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  // ===== Assessment Endpoints =====
  static ApiEndpoint<AssessmentModel> classAssessments(String classId) =>
      ApiEndpoint<AssessmentModel>.fromModel(
        '/api/v1/classes/$classId/assessments',
        AssessmentModel.fromJson,
      );

  static ApiEndpoint<List<AssessmentModel>> classAssessmentsList(
          String classId) =>
      ApiEndpoint(
        '/api/v1/classes/$classId/assessments',
        (json) => (json['assessments'] as List<dynamic>)
            .map((e) => AssessmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<void> classAssessmentsReorder(String classId) =>
      ApiEndpoint('/api/v1/classes/$classId/assessments/reorder', (_) {});

  static ApiEndpoint<AssessmentModel> assessmentDetail(String assessmentId) =>
      ApiEndpoint<AssessmentModel>.fromModel(
        '/api/v1/assessments/$assessmentId',
        AssessmentModel.fromJson,
      );

  static ApiEndpoint<AssessmentModel> assessmentPublish(String assessmentId) =>
      ApiEndpoint<AssessmentModel>.fromModel(
        '/api/v1/assessments/$assessmentId/publish',
        AssessmentModel.fromJson,
      );

  static ApiEndpoint<AssessmentModel> assessmentUnpublish(
          String assessmentId) =>
      ApiEndpoint<AssessmentModel>.fromModel(
        '/api/v1/assessments/$assessmentId/unpublish',
        AssessmentModel.fromJson,
      );

  static ApiEndpoint<AssessmentModel> assessmentReleaseResults(
          String assessmentId) =>
      ApiEndpoint<AssessmentModel>.fromModel(
        '/api/v1/assessments/$assessmentId/release-results',
        AssessmentModel.fromJson,
      );

  static ApiEndpoint<List<QuestionModel>> assessmentQuestions(
          String assessmentId) =>
      ApiEndpoint(
        '/api/v1/assessments/$assessmentId/questions',
        (json) => (json as List<dynamic>)
            .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<void> assessmentQuestionsReorder(String assessmentId) =>
      ApiEndpoint('/api/v1/assessments/$assessmentId/questions/reorder', (_) {});

  static ApiEndpoint<QuestionModel> questionDetail(String questionId) =>
      ApiEndpoint<QuestionModel>.fromModel(
        '/api/v1/questions/$questionId',
        QuestionModel.fromJson,
      );

  static ApiEndpoint<List<SubmissionSummaryModel>> assessmentSubmissions(
          String assessmentId) =>
      ApiEndpoint(
        '/api/v1/assessments/$assessmentId/submissions',
        (json) => (json['submissions'] as List<dynamic>)
            .map((e) =>
                SubmissionSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<SubmissionDetailModel> submissionDetail(
          String submissionId) =>
      ApiEndpoint<SubmissionDetailModel>.fromModel(
        '/api/v1/submissions/$submissionId',
        SubmissionDetailModel.fromJson,
      );

  static ApiEndpoint<SubmissionAnswerModel> submissionAnswerOverride(
          String answerId) =>
      ApiEndpoint<SubmissionAnswerModel>.fromModel(
        '/api/v1/submission-answers/$answerId/override',
        SubmissionAnswerModel.fromJson,
      );

  static ApiEndpoint<AssessmentStatisticsModel> assessmentStatistics(
          String assessmentId) =>
      ApiEndpoint<AssessmentStatisticsModel>.fromModel(
        '/api/v1/assessments/$assessmentId/statistics',
        AssessmentStatisticsModel.fromJson,
      );

  static ApiEndpoint<StartSubmissionResultModel> assessmentStart(
          String assessmentId) =>
      ApiEndpoint<StartSubmissionResultModel>.fromModel(
        '/api/v1/assessments/$assessmentId/start',
        StartSubmissionResultModel.fromJson,
      );

  static ApiEndpoint<void> submissionAnswers(String submissionId) =>
      ApiEndpoint(
        '/api/v1/submissions/$submissionId/answers',
        (_) {},
      );

  static ApiEndpoint<SubmissionSummaryModel> submissionSubmit(
          String submissionId) =>
      ApiEndpoint<SubmissionSummaryModel>.fromModel(
        '/api/v1/submissions/$submissionId/submit',
        SubmissionSummaryModel.fromJson,
      );

  static ApiEndpoint<StudentResultModel> submissionResults(
          String submissionId) =>
      ApiEndpoint<StudentResultModel>.fromModel(
        '/api/v1/submissions/$submissionId/results',
        StudentResultModel.fromJson,
      );

  static final assessmentsMetadata = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/assessments/metadata',
    (json) => json as Map<String, dynamic>,
  );

  // ===== Assignment Endpoints =====
  static ApiEndpoint<AssignmentModel> classAssignments(String classId) =>
      ApiEndpoint<AssignmentModel>.fromModel(
        '/api/v1/classes/$classId/assignments',
        AssignmentModel.fromJson,
      );

  static ApiEndpoint<List<AssignmentModel>> classAssignmentsList(
          String classId) =>
      ApiEndpoint(
        '/api/v1/classes/$classId/assignments',
        (json) => (json['assignments'] as List<dynamic>)
            .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<List<AssignmentModel>> classStudentAssignments(
          String classId) =>
      ApiEndpoint(
        '/api/v1/classes/$classId/student-assignments',
        (json) => (json['assignments'] as List<dynamic>)
            .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<void> classAssignmentsReorder(String classId) =>
      ApiEndpoint('/api/v1/classes/$classId/assignments/reorder', (_) {});

  static ApiEndpoint<AssignmentModel> assignmentDetail(String assignmentId) =>
      ApiEndpoint<AssignmentModel>.fromModel(
        '/api/v1/assignments/$assignmentId',
        AssignmentModel.fromJson,
      );

  static ApiEndpoint<AssignmentModel> assignmentPublish(String assignmentId) =>
      ApiEndpoint<AssignmentModel>.fromModel(
        '/api/v1/assignments/$assignmentId/publish',
        AssignmentModel.fromJson,
      );

  static ApiEndpoint<AssignmentModel> assignmentUnpublish(
          String assignmentId) =>
      ApiEndpoint<AssignmentModel>.fromModel(
        '/api/v1/assignments/$assignmentId/unpublish',
        AssignmentModel.fromJson,
      );

  static ApiEndpoint<List<SubmissionListItemModel>> assignmentSubmissions(
          String assignmentId) =>
      ApiEndpoint(
        '/api/v1/assignments/$assignmentId/submissions',
        (json) => (json['submissions'] as List<dynamic>)
            .map((e) =>
                SubmissionListItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<AssignmentSubmissionModel> assignmentSubmissionDetail(
          String submissionId) =>
      ApiEndpoint<AssignmentSubmissionModel>.fromModel(
        '/api/v1/assignment-submissions/$submissionId',
        AssignmentSubmissionModel.fromJson,
      );

  static ApiEndpoint<AssignmentSubmissionModel> assignmentSubmissionGrade(
          String submissionId) =>
      ApiEndpoint<AssignmentSubmissionModel>.fromModel(
        '/api/v1/assignment-submissions/$submissionId/grade',
        AssignmentSubmissionModel.fromJson,
      );

  static ApiEndpoint<AssignmentSubmissionModel> assignmentSubmissionReturn(
          String submissionId) =>
      ApiEndpoint<AssignmentSubmissionModel>.fromModel(
        '/api/v1/assignment-submissions/$submissionId/return',
        AssignmentSubmissionModel.fromJson,
      );

  static ApiEndpoint<AssignmentSubmissionModel> assignmentSubmit(
          String assignmentId) =>
      ApiEndpoint<AssignmentSubmissionModel>.fromModel(
        '/api/v1/assignments/$assignmentId/submit',
        AssignmentSubmissionModel.fromJson,
      );

  static ApiEndpoint<SubmissionFileModel> assignmentSubmissionUpload(
          String submissionId) =>
      ApiEndpoint<SubmissionFileModel>.fromModel(
        '/api/v1/assignment-submissions/$submissionId/upload',
        SubmissionFileModel.fromJson,
      );

  static ApiEndpoint<AssignmentSubmissionModel> assignmentSubmissionSubmit(
          String submissionId) =>
      ApiEndpoint<AssignmentSubmissionModel>.fromModel(
        '/api/v1/assignment-submissions/$submissionId/submit',
        AssignmentSubmissionModel.fromJson,
      );

  static ApiEndpoint<void> submissionFileDelete(String fileId) =>
      ApiEndpoint(
        '/api/v1/submission-files/$fileId',
        (_) {},
      );

  static ApiEndpoint<void> submissionFileDownload(String fileId) =>
      ApiEndpoint(
        '/api/v1/submission-files/$fileId/download',
        (_) {},
      );

  static final assignmentsMetadata = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/assignments/metadata',
    (json) => json as Map<String, dynamic>,
  );

  // ===== Learning Material Endpoints =====
  static ApiEndpoint<LearningMaterialModel> classMaterials(String classId) =>
      ApiEndpoint<LearningMaterialModel>.fromModel(
        '/api/v1/classes/$classId/materials',
        LearningMaterialModel.fromJson,
      );

  static ApiEndpoint<List<LearningMaterialModel>> classMaterialsList(
          String classId) =>
      ApiEndpoint(
        '/api/v1/classes/$classId/materials',
        (json) => (json['materials'] as List<dynamic>)
            .map((e) =>
                LearningMaterialModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static ApiEndpoint<MaterialDetailModel> materialDetail(String materialId) =>
      ApiEndpoint<MaterialDetailModel>.fromModel(
        '/api/v1/materials/$materialId',
        MaterialDetailModel.fromJson,
      );

  static ApiEndpoint<LearningMaterialModel> materialUpdate(String materialId) =>
      ApiEndpoint<LearningMaterialModel>.fromModel(
        '/api/v1/materials/$materialId',
        LearningMaterialModel.fromJson,
      );

  static ApiEndpoint<LearningMaterialModel> materialReorder(String materialId) =>
      ApiEndpoint<LearningMaterialModel>.fromModel(
        '/api/v1/materials/$materialId/reorder',
        LearningMaterialModel.fromJson,
      );

  static ApiEndpoint<void> classMaterialsReorder(String classId) =>
      ApiEndpoint('/api/v1/classes/$classId/materials/reorder', (_) {});

  static ApiEndpoint<MaterialFileModel> materialUploadFile(String materialId) =>
      ApiEndpoint<MaterialFileModel>.fromModel(
        '/api/v1/materials/$materialId/files',
        MaterialFileModel.fromJson,
      );

  static ApiEndpoint<void> materialFileDelete(String fileId) =>
      ApiEndpoint(
        '/api/v1/material-files/$fileId',
        (_) {},
      );

  static ApiEndpoint<void> materialFileDownload(String fileId) =>
      ApiEndpoint(
        '/api/v1/material-files/$fileId/download',
        (_) {},
      );

  static final materialsMetadata = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/materials/metadata',
    (json) => json as Map<String, dynamic>,
  );

  static final databaseId = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/database-id',
    (json) => json as Map<String, dynamic>,
  );

  // ===== Sync Endpoints (Full/Delta Optimized) =====
  static final syncPush = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/sync/push',
    (json) => json as Map<String, dynamic>,
  );

  static final syncResolveConflict = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/sync/conflicts/resolve',
    (json) => json as Map<String, dynamic>,
  );

  // ===== Full/Delta Sync Endpoints (Optimized) =====
  static final syncFull = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/sync/full',
    (json) => json as Map<String, dynamic>,
  );

  static final syncDeltas = ApiEndpoint<Map<String, dynamic>>(
    '/api/v1/sync/deltas',
    (json) => json as Map<String, dynamic>,
  );
}
