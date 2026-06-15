import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class DeleteClass {
  final ClassRepository _repository;

  DeleteClass(this._repository);

  ResultVoid call({required String classId}) {
    return _repository.deleteClass(classId: classId);
  }
}
