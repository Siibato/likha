import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class UpdateClass {
  final ClassRepository _repository;

  UpdateClass(this._repository);

  ResultFuture<ClassEntity> call(UpdateClassParams params) {
    return _repository.updateClass(
      classId: params.classId,
      title: params.title,
      description: params.description,
    );
  }
}

class UpdateClassParams {
  final String classId;
  final String? title;
  final String? description;

  UpdateClassParams({
    required this.classId,
    this.title,
    this.description,
  });
}
