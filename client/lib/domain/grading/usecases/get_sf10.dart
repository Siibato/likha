import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetSf10 {
  final GradingRepository _repository;

  GetSf10(this._repository);

  ResultFuture<Sf9Response> call(GetSf10Params params) {
    return _repository.getSf10(
      classId: params.classId,
      studentId: params.studentId,
    );
  }
}

class GetSf10Params {
  final String classId;
  final String studentId;

  GetSf10Params({required this.classId, required this.studentId});
}
