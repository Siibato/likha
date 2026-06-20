import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart'; // StudentAssignmentStatus is in here

abstract class AssignmentRepository {
  // Teacher: Assignment CRUD
  ResultFuture<MutationResult<Assignment>> createAssignment({
    required String classId,
    required String title,
    required String instructions,
    required int totalPoints,
    required bool allowsTextSubmission,
    required bool allowsFileSubmission,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    required String dueAt,
    bool isPublished = true,
    int? gradingPeriodNumber,
    String? component,
    bool? noSubmissionRequired,
  });

  ResultFuture<List<Assignment>> getAssignments({required String classId, bool publishedOnly = false, bool skipBackgroundRefresh = false});

  ResultFuture<Assignment> getAssignmentDetail({required String assignmentId});

  ResultFuture<MutationResult<Assignment>> updateAssignment({
    required String assignmentId,
    String? title,
    String? instructions,
    int? totalPoints,
    bool? allowsTextSubmission,
    bool? allowsFileSubmission,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    String? dueAt,
  });

  ResultFuture<MutationResult<void>> deleteAssignment({required String assignmentId});

  ResultFuture<MutationResult<Assignment>> publishAssignment({required String assignmentId});

  ResultFuture<MutationResult<Assignment>> unpublishAssignment({required String assignmentId});

  ResultFuture<MutationResult<void>> reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  });

  // Teacher: Submissions & Grading
  ResultFuture<List<SubmissionListItem>> getSubmissions({
    required String assignmentId,
    bool skipBackgroundRefresh = false,
  });

  ResultFuture<AssignmentSubmission> getSubmissionDetail({
    required String submissionId,
  });

  ResultFuture<MutationResult<AssignmentSubmission>> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  });

  ResultFuture<MutationResult<AssignmentSubmission>> returnSubmission({
    required String submissionId,
  });

  ResultFuture<StudentAssignmentStatus?> getStudentAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  });

  // Student: Submission flow
  ResultFuture<MutationResult<AssignmentSubmission>> createSubmission({
    required String assignmentId,
    String? textContent,
  });

  ResultFuture<MutationResult<SubmissionFile>> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
  });

  ResultFuture<MutationResult<void>> deleteFile({required String fileId});

  ResultFuture<MutationResult<AssignmentSubmission>> submitAssignment({
    required String submissionId,
  });

  ResultFuture<List<int>> downloadFile({required String fileId});
}
