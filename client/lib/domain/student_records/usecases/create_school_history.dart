import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class CreateSchoolHistory {
  final StudentRecordsRepository _repository;
  CreateSchoolHistory(this._repository);

  ResultFuture<SchoolHistory> call(CreateSchoolHistoryParams params) {
    return _repository.createSchoolHistory(
      classId: params.classId,
      studentId: params.studentId,
      data: params.data,
    );
  }
}

class CreateSchoolHistoryParams {
  final String classId;
  final String studentId;
  final Map<String, dynamic> data;
  CreateSchoolHistoryParams({required this.classId, required this.studentId, required this.data});
}
