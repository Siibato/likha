import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class CreateAssignment {
  final AssignmentRepository _repository;

  CreateAssignment(this._repository);

  ResultFuture<Assignment> call(CreateAssignmentParams params) {
    return _repository.createAssignment(
      classId: params.classId,
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

class CreateAssignmentParams {
  final String classId;
  final String title;
  final String instructions;
  final int totalPoints;
  final String submissionType;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final String dueAt;

  CreateAssignmentParams({
    required this.classId,
    required this.title,
    required this.instructions,
    required this.totalPoints,
    required this.submissionType,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    required this.dueAt,
  });
}
