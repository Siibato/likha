import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class UpdateQuestionParams {
  final String questionId;
  final Map<String, dynamic> data;

  UpdateQuestionParams({
    required this.questionId,
    required this.data,
  });
}

class UpdateQuestion {
  final AssessmentRepository _repository;

  UpdateQuestion(this._repository);

  ResultFuture<Question> call(UpdateQuestionParams params) {
    return _repository.updateQuestion(
      questionId: params.questionId,
      data: params.data,
    );
  }
}
