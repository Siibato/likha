import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetSchoolHistory {
  final StudentRecordsRepository _repository;
  GetSchoolHistory(this._repository);

  ResultFuture<List<SchoolHistory>> call(GetSchoolHistoryParams params) {
    return _repository.getSchoolHistory(classId: params.classId, studentId: params.studentId);
  }
}

class GetSchoolHistoryParams {
  final String classId;
  final String studentId;
  GetSchoolHistoryParams({required this.classId, required this.studentId});
}
