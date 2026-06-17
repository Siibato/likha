import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/setup/entities/school_settings.dart';
import 'package:likha/domain/setup/repositories/setup_repository.dart';

class GetSchoolSettings {
  final SetupRepository _repository;

  GetSchoolSettings(this._repository);

  ResultFuture<SchoolSettings?> call({bool skipBackgroundRefresh = false}) {
    return _repository.getSchoolSettings(
      skipBackgroundRefresh: skipBackgroundRefresh,
    );
  }
}
