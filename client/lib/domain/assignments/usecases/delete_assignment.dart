import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class DeleteAssignment {
  final AssignmentRepository _repository;

  DeleteAssignment(this._repository);

  ResultVoid call(String assignmentId) {
    return _repository.deleteAssignment(assignmentId: assignmentId);
  }
}
