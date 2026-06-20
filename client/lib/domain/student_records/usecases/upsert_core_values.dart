import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/core_values_record.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class UpsertCoreValues {
  final StudentRecordsRepository _repository;
  UpsertCoreValues(this._repository);

  ResultFuture<CoreValuesRecord> call(UpsertCoreValuesParams params) {
    return _repository.upsertCoreValues(classId: params.classId, studentId: params.studentId, data: params.data);
  }
}

class UpsertCoreValuesParams {
  final String classId;
  final String studentId;
  final Map<String, dynamic> data;
  UpsertCoreValuesParams({required this.classId, required this.studentId, required this.data});
}
