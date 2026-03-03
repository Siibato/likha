import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;

abstract class AssignmentLocalDataSource {
  Future<List<AssignmentModel>> getCachedAssignments(String classId);
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId);
  Future<void> cacheAssignments(List<AssignmentModel> assignments);
  Future<void> cacheAssignmentDetail(AssignmentModel assignment);
  Future<void> createSubmissionLocally({
    required String assignmentId,
    required String studentId,
    required String studentName,
  });
  Future<void> updateSubmissionTextLocally({
    required String submissionId,
    required String textContent,
  });
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  });
  Future<void> submitAssignmentLocally({
    required String submissionId,
    required String assignmentId,
  });
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId);
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId);
  Future<void> cacheSubmissions(String assignmentId, List<SubmissionListItemModel> submissions);
  Future<bool> isFileCached(String fileId);
  Future<List<int>> getCachedFileBytes(String fileId);
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes);
  Future<void> clearAllCache();
}