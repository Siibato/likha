import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/entities/general_average.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class GetGeneralAverages {
  final GradingRepository _repository;

  GetGeneralAverages(this._repository);

  ResultFuture<GeneralAverageResponse> call(String classId) {
    return _repository.getGeneralAverages(classId: classId);
  }
}
