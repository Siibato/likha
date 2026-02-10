import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class UpdateAssignment {
  final AssignmentRepository _repository;

  UpdateAssignment(this._repository);

  ResultFuture<Assignment> call(UpdateAssignmentParams params) {
    return _repository.updateAssignment(
      assignmentId: params.assignmentId,
      title: params.title,
      instructions: params.instructions,
      totalPoints: params.totalPoints,
      submissionType: params.submissionType,
      allowedFileTypes: params.allowedFileTypes,
      maxFileSizeMb: params.maxFileSizeMb,
      dueAt: params.dueAt,
    );
  }
}

class UpdateAssignmentParams {
  final String assignmentId;
  final String? title;
  final String? instructions;
  final int? totalPoints;
  final String? submissionType;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String? dueAt;

  UpdateAssignmentParams({
    required this.assignmentId,
    this.title,
    this.instructions,
    this.totalPoints,
    this.submissionType,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    this.dueAt,
  });
}
