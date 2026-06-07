import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class PublishAssignment {
  final AssignmentRepository _repository;

  PublishAssignment(this._repository);

  ResultFuture<Assignment> call(String assignmentId) {
    return _repository.publishAssignment(assignmentId: assignmentId);
  }
}
