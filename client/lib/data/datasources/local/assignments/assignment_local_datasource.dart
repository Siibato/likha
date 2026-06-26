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
  Future<void> cacheAssignmentDetail(AssignmentModel assignment, {Transaction? txn});
  Future<void> insertAssignment(AssignmentModel assignment, {Transaction? txn});
  Future<String> createSubmission({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
    String? queueEntryId,
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
    Transaction? txn,
    String? queueEntryId,
  });
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId);
  Future<String?> getAssignmentIdForSubmission(String submissionId);
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
    String? queueEntryId,
  });
  Future<void> returnSubmission({required String submissionId, String? queueEntryId});
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission, {Transaction? txn});
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file, {Transaction? txn});
  Future<void> softDeleteSubmissionFile(String fileId, {Transaction? txn});
  Future<void> markAssignmentPublished({required String assignmentId, String? queueEntryId});
  Future<void> markAssignmentUnpublished({required String assignmentId, String? queueEntryId});
  Future<void> updateAssignmentOrder({
    required String assignmentId,
    required int orderIndex,
    Transaction? txn,
  });
  Future<void> deleteAssignment({required String assignmentId, Transaction? txn});
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
  Future<void> cacheAssignmentDetail(AssignmentModel assignment, {Transaction? txn}) =>
      ops.cacheAssignmentDetail(localDatabase, assignment, txn: txn);

  @override
  Future<void> insertAssignment(AssignmentModel assignment, {Transaction? txn}) =>
      ops.insertAssignment(localDatabase, assignment, txn: txn);

  @override
  Future<String> createSubmission({
    required String assignmentId,
    required String studentId,
    String studentName = '',
    String? textContent,
    String? queueEntryId,
  }) =>
      ops.createSubmission(
        localDatabase,
        syncQueue,
        assignmentId,
        studentId,
        studentName,
        textContent,
        queueEntryId: queueEntryId,
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
    Transaction? txn,
    String? queueEntryId,
  }) =>
      ops.submitAssignment(localDatabase, syncQueue, submissionId, assignmentId, txn: txn, queueEntryId: queueEntryId);

  @override
  Future<AssignmentSubmissionModel?> getCachedSubmission(String submissionId) =>
      ops.getCachedSubmission(localDatabase, submissionId);

  @override
  Future<String?> getAssignmentIdForSubmission(String submissionId) =>
      ops.getAssignmentIdForSubmission(localDatabase, submissionId);

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
    String? queueEntryId,
  }) =>
      ops.gradeSubmission(localDatabase, syncQueue, submissionId, score, feedback, queueEntryId: queueEntryId);

  @override
  Future<void> returnSubmission({required String submissionId, String? queueEntryId}) =>
      ops.returnSubmission(localDatabase, syncQueue, submissionId, queueEntryId: queueEntryId);

  @override
  Future<void> cacheSubmissionDetail(AssignmentSubmissionModel submission, {Transaction? txn}) =>
      ops.cacheSubmissionDetail(localDatabase, submission, txn: txn);

  @override
  Future<void> cacheSubmissionFile(String submissionId, SubmissionFileModel file, {Transaction? txn}) =>
      ops.cacheSubmissionFile(localDatabase, submissionId, file, txn: txn);

  @override
  Future<void> softDeleteSubmissionFile(String fileId, {Transaction? txn}) =>
      ops.softDeleteSubmissionFile(localDatabase, fileId, txn: txn);

  @override
  Future<void> markAssignmentPublished({required String assignmentId, String? queueEntryId}) =>
      ops.markAssignmentPublished(localDatabase, syncQueue, assignmentId, queueEntryId: queueEntryId);

  @override
  Future<void> markAssignmentUnpublished({required String assignmentId, String? queueEntryId}) =>
      ops.markAssignmentUnpublished(localDatabase, syncQueue, assignmentId, queueEntryId: queueEntryId);

  @override
  Future<void> updateAssignmentOrder({
    required String assignmentId,
    required int orderIndex,
    Transaction? txn,
  }) =>
      ops.updateAssignmentOrder(localDatabase, assignmentId, orderIndex, txn: txn);

  @override
  Future<void> deleteAssignment({required String assignmentId, Transaction? txn}) =>
      ops.deleteAssignment(localDatabase, assignmentId, txn: txn);

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