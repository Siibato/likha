import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/school_history.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class UpdateSchoolHistory {
  final StudentRecordsRepository _repository;
  UpdateSchoolHistory(this._repository);

  ResultFuture<SchoolHistory> call(UpdateSchoolHistoryParams params) {
    return _repository.updateSchoolHistory(
      classId: params.classId,
      studentId: params.studentId,
      historyId: params.historyId,
      data: params.data,
    );
  }
}

class UpdateSchoolHistoryParams {
  final String classId;
  final String studentId;
  final String historyId;
  final Map<String, dynamic> data;
  UpdateSchoolHistoryParams({required this.classId, required this.studentId, required this.historyId, required this.data});
}
