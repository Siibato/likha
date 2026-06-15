import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class ReorderAllAssignments {
  final AssignmentRepository _repository;

  const ReorderAllAssignments(this._repository);

  ResultVoid call({
    required String classId,
    required List<String> assignmentIds,
  }) {
    return _repository.reorderAllAssignments(
      classId: classId,
      assignmentIds: assignmentIds,
    );
  }
}
