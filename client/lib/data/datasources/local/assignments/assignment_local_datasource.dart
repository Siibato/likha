import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/assignments/assignment_model.dart';
import 'package:likha/data/models/assignments/assignment_submission_model.dart'
    show AssignmentSubmissionModel, SubmissionListItemModel;
import 'package:likha/data/models/assignments/submission_file_model.dart';
import 'operations/assignments.dart' as ops;

abstract class AssignmentLocalDataSource {
  LocalDatabase get localDatabase;

  Future<List<AssignmentModel>> getCachedAssignments(String classId, {bool publishedOnly = false, String? studentId});
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId);
  Future<void> cacheAssignments(List<AssignmentModel> assignments);
  Future<void> cacheAssignmentDetail(AssignmentModel assignment);
  Future<void> insertAssignment(AssignmentModel assignment, {Transaction? txn});
  Future<String> createSubmission({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
  });
  Future<void> updateSubmissionText({
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
  Future<void> submitAssignment({
    required String submissionId,
    required String assignmentId,
  });
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId);
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId);
  Future<List<SubmissionFileModel>> getCachedSubmissionFiles(String submissionId);
  Future<void> cacheSubmissions(String assignmentId, List<SubmissionListItemModel> submissions);
  Future<bool> isFileCached(String fileId);
  Future<List<int>> getCachedFileBytes(String fileId);
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes);
  Future<void> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  });
  Future<void> returnSubmission({required String submissionId});
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission);
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file);
  Future<void> softDeleteSubmissionFile(String fileId);
  Future<void> markAssignmentPublished({required String assignmentId});
  Future<void> markAssignmentUnpublished({required String assignmentId});
  Future<void> updateAssignmentOrder({
    required String assignmentId,
    required int orderIndex,
  });
  Future<void> deleteAssignment({required String assignmentId});
  Future<void> clearAllCache();
  Future<(String submissionId, String status, int? score)?> getStudentSubmissionForAssignment(
    String assignmentId,
    String studentId,
  );
  Future<void> clearStudentAssignmentSubmission(
    String assignmentId,
    String studentId,
  );
}

class AssignmentLocalDataSourceImpl implements AssignmentLocalDataSource {
  @override
  final LocalDatabase localDatabase;
  final SyncQueue syncQueue;

  AssignmentLocalDataSourceImpl(this.localDatabase, this.syncQueue);

  @override
  Future<List<AssignmentModel>> getCachedAssignments(
    String classId, {
    bool publishedOnly = false,
    String? studentId,
  }) =>
      ops.getCachedAssignments(localDatabase, classId, publishedOnly, studentId);

  @override
  Future<AssignmentModel> getCachedAssignmentDetail(String assignmentId) =>
      ops.getCachedAssignmentDetail(localDatabase, assignmentId);

  @override
  Future<void> cacheAssignments(List<AssignmentModel> assignments) =>
      ops.cacheAssignments(localDatabase, assignments);

  @override
  Future<void> cacheAssignmentDetail(AssignmentModel assignment) =>
      ops.cacheAssignmentDetail(localDatabase, assignment);

  @override
  Future<void> insertAssignment(AssignmentModel assignment, {Transaction? txn}) =>
      ops.insertAssignment(localDatabase, assignment, txn: txn);

  @override
  Future<String> createSubmission({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
  }) =>
      ops.createSubmission(
        localDatabase,
        syncQueue,
        assignmentId,
        studentId,
        studentName,
        textContent,
      );

  @override
  Future<void> updateSubmissionText({
    required String submissionId,
    required String textContent,
  }) =>
      ops.updateSubmissionText(localDatabase, syncQueue, submissionId, textContent);

  @override
  Future<void> stageFileForUpload({
    required String submissionId,
    required String fileName,
    required String fileType,
    required int fileSize,
    required String localPath,
  }) =>
      ops.stageFileForUpload(
        localDatabase,
        syncQueue,
        submissionId,
        fileName,
        fileType,
        fileSize,
        localPath,
      );

  @override
  Future<void> submitAssignment({
    required String submissionId,
    required String assignmentId,
  }) =>
      ops.submitAssignment(localDatabase, syncQueue, submissionId, assignmentId);

  @override
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId) =>
      ops.getCachedSubmission(localDatabase, submissionId);

  @override
  Future<List<SubmissionListItemModel>> getCachedSubmissions(String assignmentId) =>
      ops.getCachedSubmissions(localDatabase, assignmentId);

  @override
  Future<List<SubmissionFileModel>> getCachedSubmissionFiles(String submissionId) async {
    final db = await localDatabase.database;
    return ops.getCachedSubmissionFiles(db, submissionId);
  }

  @override
  Future<void> cacheSubmissions(
    String assignmentId,
    List<SubmissionListItemModel> submissions,
  ) =>
      ops.cacheSubmissions(localDatabase, assignmentId, submissions);

  @override
  Future<bool> isFileCached(String fileId) =>
      ops.isFileCached(localDatabase, fileId);

  @override
  Future<List<int>> getCachedFileBytes(String fileId) =>
      ops.getCachedFileBytes(localDatabase, fileId);

  @override
  Future<void> cacheFileBytes(String fileId, String fileName, List<int> bytes) =>
      ops.cacheFileBytes(localDatabase, fileId, fileName, bytes);

  @override
  Future<void> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  }) =>
      ops.gradeSubmission(localDatabase, syncQueue, submissionId, score, feedback);

  @override
  Future<void> returnSubmission({required String submissionId}) =>
      ops.returnSubmission(localDatabase, syncQueue, submissionId);

  @override
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission) =>
      ops.cacheSubmissionDetail(localDatabase, submission);

  @override
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file) =>
      ops.cacheSubmissionFile(localDatabase, submissionId, file);

  @override
  Future<void> softDeleteSubmissionFile(String fileId) =>
      ops.softDeleteSubmissionFile(localDatabase, fileId);

  @override
  Future<void> markAssignmentPublished({required String assignmentId}) =>
      ops.markAssignmentPublished(localDatabase, syncQueue, assignmentId);

  @override
  Future<void> markAssignmentUnpublished({required String assignmentId}) =>
      ops.markAssignmentUnpublished(localDatabase, syncQueue, assignmentId);

  @override
  Future<void> updateAssignmentOrder({
    required String assignmentId,
    required int orderIndex,
  }) =>
      ops.updateAssignmentOrder(localDatabase, assignmentId, orderIndex);

  @override
  Future<void> deleteAssignment({required String assignmentId}) =>
      ops.deleteAssignment(localDatabase, assignmentId);

  @override
  Future<void> clearAllCache() =>
      ops.clearAllCache(localDatabase);

  @override
  Future<(String submissionId, String status, int? score)?>
      getStudentSubmissionForAssignment(
    String assignmentId,
    String studentId,
  ) =>
      ops.getStudentSubmissionForAssignment(
        localDatabase,
        assignmentId,
        studentId,
      );

  @override
  Future<void> clearStudentAssignmentSubmission(
    String assignmentId,
    String studentId,
  ) =>
      ops.clearStudentAssignmentSubmission(
        localDatabase,
        assignmentId,
        studentId,
      );
}