import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class CreateAssignment {
  final AssignmentRepository _repository;

  CreateAssignment(this._repository);

  ResultFuture<MutationResult<Assignment>> call(CreateAssignmentParams params) {
    return _repository.createAssignment(
      classId: params.classId,
      title: params.title,
      instructions: params.instructions,
      totalPoints: params.totalPoints,
      allowsTextSubmission: params.allowsTextSubmission,
      allowsFileSubmission: params.allowsFileSubmission,
      allowedFileTypes: params.allowedFileTypes,
      maxFileSizeMb: params.maxFileSizeMb,
      dueAt: params.dueAt,
      isPublished: params.isPublished,
      termNumber: params.termNumber,
      component: params.component,
      noSubmissionRequired: params.noSubmissionRequired,
    );
  }
}

class CreateAssignmentParams {
  final String classId;
  final String title;
  final String instructions;
  final int totalPoints;
  final bool allowsTextSubmission;
  final bool allowsFileSubmission;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String dueAt;
  final bool isPublished;
  final int? termNumber;
  final String? component;
  final bool? noSubmissionRequired;

  CreateAssignmentParams({
    required this.classId,
    required this.title,
    required this.instructions,
    required this.totalPoints,
    required this.allowsTextSubmission,
    required this.allowsFileSubmission,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    required this.dueAt,
    this.isPublished = true,
    this.termNumber,
    this.component,
    this.noSubmissionRequired,
  });
}
