import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/grading/repositories/grading_repository.dart';

class UpdateGradingConfig {
  final GradingRepository _repository;

  UpdateGradingConfig(this._repository);

  ResultVoid call({
    required String classId,
    required List<Map<String, dynamic>> configs,
  }) {
    return _repository.updateGradingConfig(classId: classId, configs: configs);
  }
}
