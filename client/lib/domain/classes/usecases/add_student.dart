import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class AddStudent {
  final ClassRepository _repository;

  AddStudent(this._repository);

  ResultFuture<Participant> call(AddStudentParams params) {
    return _repository.addStudent(
      classId: params.classId,
      studentId: params.studentId,
    );
  }
}

class AddStudentParams {
  final String classId;
  final String studentId;

  AddStudentParams({required this.classId, required this.studentId});
}
