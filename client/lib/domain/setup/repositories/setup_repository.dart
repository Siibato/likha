import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_details.dart';

abstract class SetupRepository {
  ResultFuture<SchoolDetails> getSchoolDetails({
    bool skipBackgroundRefresh = false,
  });

  ResultFuture<MutationResult<SchoolDetails>> updateSchoolDetails({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
  });

  ResultFuture<MutationResult<SchoolDetails>> updateSchoolCode({
    required String schoolCode,
  });
}
