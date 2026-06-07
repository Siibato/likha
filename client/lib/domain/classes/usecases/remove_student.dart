import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class RemoveStudent {
  final ClassRepository _repository;

  RemoveStudent(this._repository);

  ResultVoid call(RemoveStudentParams params) {
    return _repository.removeStudent(
      classId: params.classId,
      studentId: params.studentId,
    );
  }
}

class RemoveStudentParams {
  final String classId;
  final String studentId;

  RemoveStudentParams({required this.classId, required this.studentId});
}
