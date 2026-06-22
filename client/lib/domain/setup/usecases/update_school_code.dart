import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_details.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';

class UpdateSchoolCode {
  final SetupRepository _repository;

  UpdateSchoolCode(this._repository);

  ResultFuture<MutationResult<SchoolDetails>> call({
    required String schoolCode,
  }) {
    return _repository.updateSchoolCode(schoolCode: schoolCode);
  }
}
