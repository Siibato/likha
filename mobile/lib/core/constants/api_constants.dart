import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  // Auth endpoints
  static const String checkUsername = '/api/v1/auth/check-username';
  static const String activate = '/api/v1/auth/activate';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String me = '/api/v1/auth/me';
  static const String logout = '/api/v1/auth/logout';

  // Admin endpoints
  static const String accounts = '/api/v1/auth/accounts';
  static const String accountsReset = '/api/v1/auth/accounts/reset';
  static const String accountsLock = '/api/v1/auth/accounts/lock';
  static String accountUpdate(String userId) =>
      '/api/v1/auth/accounts/$userId';
  static String accountLogs(String userId) =>
      '/api/v1/auth/accounts/$userId/logs';

  // Class endpoints
  static const String classes = '/api/v1/classes';
  static String classDetail(String classId) => '/api/v1/classes/$classId';
  static String classStudents(String classId) =>
      '/api/v1/classes/$classId/students';
  static String classStudent(String classId, String studentId) =>
      '/api/v1/classes/$classId/students/$studentId';
  static const String searchStudents = '/api/v1/students/search';

  // Assessment endpoints
  static String classAssessments(String classId) =>
      '/api/v1/classes/$classId/assessments';
  static String assessmentDetail(String assessmentId) =>
      '/api/v1/assessments/$assessmentId';
  static String assessmentPublish(String assessmentId) =>
      '/api/v1/assessments/$assessmentId/publish';
  static String assessmentReleaseResults(String assessmentId) =>
      '/api/v1/assessments/$assessmentId/release-results';
  static String assessmentQuestions(String assessmentId) =>
      '/api/v1/assessments/$assessmentId/questions';
  static String questionDetail(String questionId) =>
      '/api/v1/questions/$questionId';
  static String assessmentSubmissions(String assessmentId) =>
      '/api/v1/assessments/$assessmentId/submissions';
  static String submissionDetail(String submissionId) =>
      '/api/v1/submissions/$submissionId';
  static String submissionAnswerOverride(String answerId) =>
      '/api/v1/submission-answers/$answerId/override';
  static String assessmentStatistics(String assessmentId) =>
      '/api/v1/assessments/$assessmentId/statistics';
  static String assessmentStart(String assessmentId) =>
      '/api/v1/assessments/$assessmentId/start';
  static String submissionAnswers(String submissionId) =>
      '/api/v1/submissions/$submissionId/answers';
  static String submissionSubmit(String submissionId) =>
      '/api/v1/submissions/$submissionId/submit';
  static String submissionResults(String submissionId) =>
      '/api/v1/submissions/$submissionId/results';

  // Assignment endpoints
  static String classAssignments(String classId) =>
      '/api/v1/classes/$classId/assignments';
  static String classStudentAssignments(String classId) =>
      '/api/v1/classes/$classId/student-assignments';
  static String assignmentDetail(String assignmentId) =>
      '/api/v1/assignments/$assignmentId';
  static String assignmentPublish(String assignmentId) =>
      '/api/v1/assignments/$assignmentId/publish';
  static String assignmentSubmissions(String assignmentId) =>
      '/api/v1/assignments/$assignmentId/submissions';
  static String assignmentSubmissionDetail(String submissionId) =>
      '/api/v1/assignment-submissions/$submissionId';
  static String assignmentSubmissionGrade(String submissionId) =>
      '/api/v1/assignment-submissions/$submissionId/grade';
  static String assignmentSubmissionReturn(String submissionId) =>
      '/api/v1/assignment-submissions/$submissionId/return';
  static String assignmentSubmit(String assignmentId) =>
      '/api/v1/assignments/$assignmentId/submit';
  static String assignmentSubmissionUpload(String submissionId) =>
      '/api/v1/assignment-submissions/$submissionId/upload';
  static String assignmentSubmissionSubmit(String submissionId) =>
      '/api/v1/assignment-submissions/$submissionId/submit';
  static String submissionFileDelete(String fileId) =>
      '/api/v1/submission-files/$fileId';
  static String submissionFileDownload(String fileId) =>
      '/api/v1/submission-files/$fileId/download';

  // Learning Material endpoints
  static String classMaterials(String classId) =>
      '/api/v1/classes/$classId/materials';
  static String materialDetail(String materialId) =>
      '/api/v1/materials/$materialId';
  static String materialReorder(String materialId) =>
      '/api/v1/materials/$materialId/reorder';
  static String materialUploadFile(String materialId) =>
      '/api/v1/materials/$materialId/files';
  static String materialFileDelete(String fileId) =>
      '/api/v1/material-files/$fileId';
  static String materialFileDownload(String fileId) =>
      '/api/v1/material-files/$fileId/download';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
