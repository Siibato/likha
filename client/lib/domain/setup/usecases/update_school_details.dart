import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_details.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';

class UpdateSchoolDetails {
  final SetupRepository _repository;

  UpdateSchoolDetails(this._repository);

  ResultFuture<MutationResult<SchoolDetails>> call({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
  }) {
    return _repository.updateSchoolDetails(
      schoolName: schoolName,
      schoolRegion: schoolRegion,
      schoolDivision: schoolDivision,
      schoolYear: schoolYear,
      schoolCode: schoolCode,
      schoolDistrict: schoolDistrict,
      schoolHeadName: schoolHeadName,
      schoolHeadPosition: schoolHeadPosition,
    );
  }
}
