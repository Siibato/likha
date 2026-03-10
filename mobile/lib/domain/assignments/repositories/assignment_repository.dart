import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart'; // StudentAssignmentStatus is in here

abstract class AssignmentRepository {
  // Teacher: Assignment CRUD
  ResultFuture<Assignment> createAssignment({
    required String classId,
    required String title,
    required String instructions,
    required int totalPoints,
    required String submissionType,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    required String dueAt,
    bool isPublished = true,
  });

  ResultFuture<List<Assignment>> getAssignments({required String classId, bool publishedOnly = false, bool skipBackgroundRefresh = false});

  ResultFuture<Assignment> getAssignmentDetail({required String assignmentId});

  ResultFuture<Assignment> updateAssignment({
    required String assignmentId,
    String? title,
    String? instructions,
    int? totalPoints,
    String? submissionType,
    String? allowedFileTypes,
    int? maxFileSizeMb,
    String? dueAt,
  });

  ResultVoid deleteAssignment({required String assignmentId});

  ResultFuture<Assignment> publishAssignment({required String assignmentId});

  ResultVoid reorderAllAssignments({
    required String classId,
    required List<String> assignmentIds,
  });

  // Teacher: Submissions & Grading
  ResultFuture<List<SubmissionListItem>> getSubmissions({
    required String assignmentId,
  });

  ResultFuture<AssignmentSubmission> getSubmissionDetail({
    required String submissionId,
  });

  ResultFuture<AssignmentSubmission> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
  });

  ResultFuture<AssignmentSubmission> returnSubmission({
    required String submissionId,
  });

  ResultFuture<StudentAssignmentStatus?> getStudentAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  });

  // Student: Submission flow
  ResultFuture<AssignmentSubmission> createSubmission({
    required String assignmentId,
    String? textContent,
  });

  ResultFuture<SubmissionFile> uploadFile({
    required String submissionId,
    required String filePath,
    required String fileName,
  });

  ResultVoid deleteFile({required String fileId});

  ResultFuture<AssignmentSubmission> submitAssignment({
    required String submissionId,
  });

  ResultFuture<List<int>> downloadFile({required String fileId});
}
