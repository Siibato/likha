import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetPreviousSubjects {
  final StudentRecordsRepository _repository;
  GetPreviousSubjects(this._repository);

  ResultFuture<List<PreviousSubject>> call(GetPreviousSubjectsParams params) {
    return _repository.getPreviousSubjects(
      classId: params.classId,
      studentId: params.studentId,
      schoolHistoryId: params.schoolHistoryId,
    );
  }
}

class GetPreviousSubjectsParams {
  final String classId;
  final String studentId;
  final String? schoolHistoryId;
  GetPreviousSubjectsParams({required this.classId, required this.studentId, this.schoolHistoryId});
}
