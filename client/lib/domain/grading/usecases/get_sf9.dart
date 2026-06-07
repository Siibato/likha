import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetSf9 {
  final GradingRepository _repository;

  GetSf9(this._repository);

  ResultFuture<Sf9Response> call(GetSf9Params params) {
    return _repository.getSf9(
      classId: params.classId,
      studentId: params.studentId,
    );
  }
}

class GetSf9Params {
  final String classId;
  final String studentId;

  GetSf9Params({required this.classId, required this.studentId});
}
