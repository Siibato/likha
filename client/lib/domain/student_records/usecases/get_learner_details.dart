import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetLearnerDetails {
  final StudentRecordsRepository _repository;
  GetLearnerDetails(this._repository);

  ResultFuture<LearnerDetails?> call(GetLearnerDetailsParams params) {
    return _repository.getLearnerDetails(classId: params.classId, studentId: params.studentId);
  }
}

class GetLearnerDetailsParams {
  final String classId;
  final String studentId;
  GetLearnerDetailsParams({required this.classId, required this.studentId});
}
