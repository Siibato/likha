import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_details.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';

class GetSchoolDetails {
  final SetupRepository _repository;

  GetSchoolDetails(this._repository);

  ResultFuture<SchoolDetails> call({bool skipBackgroundRefresh = false}) {
    return _repository.getSchoolDetails(
      skipBackgroundRefresh: skipBackgroundRefresh,
    );
  }
}
