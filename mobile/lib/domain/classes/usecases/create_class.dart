import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class CreateClass {
  final ClassRepository _repository;

  CreateClass(this._repository);

  ResultFuture<ClassEntity> call(CreateClassParams params) {
    return _repository.createClass(
      title: params.title,
      description: params.description,
      teacherId: params.teacherId,
    );
  }
}

class CreateClassParams {
  final String title;
  final String? description;
  final String? teacherId;

  CreateClassParams({
    required this.title,
    this.description,
    this.teacherId,
  });
}
