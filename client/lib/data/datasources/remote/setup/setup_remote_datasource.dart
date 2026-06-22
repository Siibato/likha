import 'package:likha/core/network/dio_client.dart';
import 'package:likha/data/models/setup/school_details_model.dart';
import 'operations/get_school_details.dart' as ops_get;
import 'operations/update_school_details.dart' as ops_update;
import 'operations/update_school_code.dart' as ops_code;

abstract class SetupRemoteDataSource {
  Future<SchoolDetailsModel> getSchoolDetails();
  Future<SchoolDetailsModel> updateSchoolDetails({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
    String? idempotencyKey,
  });
  Future<void> updateSchoolCode({
    required String schoolCode,
    String? idempotencyKey,
  });
}

class SetupRemoteDataSourceImpl implements SetupRemoteDataSource {
  final DioClient _dioClient;

  SetupRemoteDataSourceImpl(this._dioClient);

  @override
  Future<SchoolDetailsModel> getSchoolDetails() =>
      ops_get.getSchoolDetails(_dioClient);

  @override
  Future<SchoolDetailsModel> updateSchoolDetails({
    required String schoolName,
    required String schoolRegion,
    required String schoolDivision,
    required String schoolYear,
    required String schoolCode,
    String? schoolDistrict,
    String? schoolHeadName,
    String? schoolHeadPosition,
    String? idempotencyKey,
  }) =>
      ops_update.updateSchoolDetails(
        _dioClient,
        schoolName: schoolName,
        schoolRegion: schoolRegion,
        schoolDivision: schoolDivision,
        schoolYear: schoolYear,
        schoolCode: schoolCode,
        schoolDistrict: schoolDistrict,
        schoolHeadName: schoolHeadName,
        schoolHeadPosition: schoolHeadPosition,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> updateSchoolCode({
    required String schoolCode,
    String? idempotencyKey,
  }) =>
      ops_code.updateSchoolCode(
        _dioClient,
        schoolCode: schoolCode,
        idempotencyKey: idempotencyKey,
      );
}
