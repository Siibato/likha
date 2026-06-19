import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetCoreValues {
  final StudentRecordsRepository _repository;
  GetCoreValues(this._repository);

  ResultFuture<List<CoreValuesRecord>> call(GetCoreValuesParams params) {
    return _repository.getCoreValues(classId: params.classId, studentId: params.studentId, schoolYear: params.schoolYear);
  }
}

class GetCoreValuesParams {
  final String classId;
  final String studentId;
  final String? schoolYear;
  GetCoreValuesParams({required this.classId, required this.studentId, this.schoolYear});
}
