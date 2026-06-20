import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class DeleteAssignment {
  final AssignmentRepository _repository;

  DeleteAssignment(this._repository);

  ResultFuture<MutationResult<void>> call(String assignmentId) {
    return _repository.deleteAssignment(assignmentId: assignmentId);
  }
}
