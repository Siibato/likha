import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/domain/classes/repositories/class_repository.dart';

class GetMyClasses {
  final ClassRepository _repository;

  GetMyClasses(this._repository);

  ResultFuture<List<ClassEntity>> call() {
    return _repository.getMyClasses();
  }
}
