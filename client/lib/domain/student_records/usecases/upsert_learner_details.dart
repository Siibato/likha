import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class UpsertLearnerDetails {
  final StudentRecordsRepository _repository;
  UpsertLearnerDetails(this._repository);

  ResultFuture<LearnerDetails> call(UpsertLearnerDetailsParams params) {
    return _repository.upsertLearnerDetails(
      classId: params.classId,
      studentId: params.studentId,
      data: params.data,
    );
  }
}

class UpsertLearnerDetailsParams {
  final String classId;
  final String studentId;
  final Map<String, dynamic> data;
  UpsertLearnerDetailsParams({required this.classId, required this.studentId, required this.data});
}
