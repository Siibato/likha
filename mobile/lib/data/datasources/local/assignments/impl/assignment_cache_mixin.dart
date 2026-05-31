import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';
import '../assignment_local_datasource_base.dart';
import 'operations/cache/cache_assignments.dart';
import 'operations/cache/cache_assignment_detail.dart';
import 'operations/cache/cache_submissions.dart';
import 'operations/cache/cache_submission_detail.dart';
import 'operations/cache/cache_submission_file.dart';

mixin AssignmentCacheMixin on AssignmentLocalDataSourceBase {
  @override
  Future<void> cacheAssignments(List<AssignmentModel> assignments) async {
    return cacheAssignmentsOp(localDatabase, enc, assignments);
  }

  @override
  Future<void> cacheAssignmentDetail(AssignmentModel assignment) async {
    return cacheAssignmentDetailOp(localDatabase, enc, assignment);
  }

  @override
  Future<void> cacheSubmissions(String assignmentId, List<SubmissionListItemModel> submissions) async {
    return cacheSubmissionsOp(localDatabase, assignmentId, submissions);
  }

  @override
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission) async {
    return cacheSubmissionDetailOp(localDatabase, enc, submission);
  }

  @override
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file) async {
    return cacheSubmissionFileOp(localDatabase, submissionId, file);
  }
}