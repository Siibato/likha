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
      teacherUsername: params.teacherUsername,
      teacherFullName: params.teacherFullName,
      isAdvisory: params.isAdvisory,
    );
  }
}

class CreateClassParams {
  final String title;
  final String? description;
  final String? teacherId;
  final String? teacherUsername;
  final String? teacherFullName;
  final bool isAdvisory;

  CreateClassParams({
    required this.title,
    this.description,
    this.teacherId,
    this.teacherUsername,
    this.teacherFullName,
    this.isAdvisory = false,
  });
}
