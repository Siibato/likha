import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';

class UpdateSchoolSettings {
  final SetupRepository _repository;

  UpdateSchoolSettings(this._repository);

  ResultFuture<MutationResult<SchoolSettings>> call({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
  }) {
    return _repository.updateSchoolSettings(
      schoolName: schoolName,
      schoolRegion: schoolRegion,
      schoolDivision: schoolDivision,
      schoolYear: schoolYear,
      schoolCode: schoolCode,
      schoolDistrict: schoolDistrict,
    );
  }
}
