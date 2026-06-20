import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/previous_subject.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class UpsertPreviousSubject {
  final StudentRecordsRepository _repository;
  UpsertPreviousSubject(this._repository);

  ResultFuture<PreviousSubject> call(UpsertPreviousSubjectParams params) {
    return _repository.upsertPreviousSubject(
      classId: params.classId,
      studentId: params.studentId,
      data: params.data,
    );
  }
}

class UpsertPreviousSubjectParams {
  final String classId;
  final String studentId;
  final Map<String, dynamic> data;
  UpsertPreviousSubjectParams({required this.classId, required this.studentId, required this.data});
}
