import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/repositories/assignment_repository.dart';

class GetAssignments {
  final AssignmentRepository _repository;

  GetAssignments(this._repository);

  ResultFuture<List<Assignment>> call(String classId, {bool publishedOnly = false}) {
    return _repository.getAssignments(classId: classId, publishedOnly: publishedOnly);
  }
}
