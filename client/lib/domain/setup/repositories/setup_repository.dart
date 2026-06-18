import 'package:likha/core/sync/mutation_result.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';

abstract class SetupRepository {
  ResultFuture<SchoolSettings> getSchoolSettings({
    bool skipBackgroundRefresh = false,
  });

  ResultFuture<MutationResult<SchoolSettings>> updateSchoolSettings({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
  });

  ResultFuture<MutationResult<SchoolSettings>> updateSchoolCode({
    required String schoolCode,
  });
}
