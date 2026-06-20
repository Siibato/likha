import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class DeleteSchoolHistory {
  final StudentRecordsRepository _repository;
  DeleteSchoolHistory(this._repository);

  ResultFuture<void> call(DeleteSchoolHistoryParams params) {
    return _repository.deleteSchoolHistory(
      classId: params.classId,
      studentId: params.studentId,
      historyId: params.historyId,
    );
  }
}

class DeleteSchoolHistoryParams {
  final String classId;
  final String studentId;
  final String historyId;
  DeleteSchoolHistoryParams({required this.classId, required this.studentId, required this.historyId});
}
