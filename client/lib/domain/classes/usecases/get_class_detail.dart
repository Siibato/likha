import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class GetClassDetail {
  final ClassRepository _repository;

  GetClassDetail(this._repository);

  ResultFuture<ClassDetail> call(String classId) {
    return _repository.getClassDetail(classId: classId);
  }
}
