import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';
import '../assignment_local_datasource_base.dart';
import 'operations/query/get_cached_assignments.dart' hide getStudentSubmissionForAssignmentOp;
import 'operations/query/get_cached_assignment_detail.dart';
import 'operations/query/get_cached_submission.dart';
import 'operations/query/get_cached_submission_files.dart';
import 'operations/query/get_cached_submissions.dart';
import 'operations/query/get_student_submission_for_assignment.dart';
import 'operations/query/delete_assignment_local.dart';

mixin AssignmentQueryMixin on AssignmentLocalDataSourceBase {
  @override
  Future<List<AssignmentModel>> getCachedAssignments(String classId, {bool publishedOnly = false, String? studentId}) async {
    return getCachedAssignmentsOp(localDatabase, classId, publishedOnly, studentId);
  }

  @override
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId) async {
    return getCachedAssignmentDetailOp(localDatabase, assignmentId);
  }

  @override
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId) async {
    return getCachedSubmissionOp(localDatabase, submissionId);
  }

  @override
  Future<List<SubmissionFileModel>> getCachedSubmissionFiles(String submissionId) async {
    final db = await localDatabase.database;
    return getCachedSubmissionFilesOp(db, submissionId);
  }

  @override
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId) async {
    return getCachedSubmissionsOp(localDatabase, assignmentId);
  }

  @override
  Future<(String submissionId, String status, int? score)?> getStudentSubmissionForAssignment(
    String assignmentId,
    String studentId,
  ) async {
    return getStudentSubmissionForAssignmentOp(localDatabase, assignmentId, studentId);
  }

  @override
  Future<void> deleteAssignmentLocal({required String assignmentId}) async {
    return deleteAssignmentLocalOp(localDatabase, assignmentId);
  }
}