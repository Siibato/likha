import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/student_records/entities/sf10_response.dart';
import 'package:likha/domain/student_records/repositories/student_records_repository.dart';

class GetSf10V2 {
  final StudentRecordsRepository _repository;
  GetSf10V2(this._repository);

  ResultFuture<Sf10Response> call(GetSf10V2Params params) {
    return _repository.getSf10(classId: params.classId, studentId: params.studentId);
  }
}

class GetSf10V2Params {
  final String classId;
  final String studentId;
  GetSf10V2Params({required this.classId, required this.studentId});
}
