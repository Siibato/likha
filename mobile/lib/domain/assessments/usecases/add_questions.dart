import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class AddQuestions {
  final AssessmentRepository _repository;

  AddQuestions(this._repository);

  ResultFuture<List<Question>> call(AddQuestionsParams params) {
    return _repository.addQuestions(
      assessmentId: params.assessmentId,
      questions: params.questions,
    );
  }
}

class AddQuestionsParams {
  final String assessmentId;
  final List<Map<String, dynamic>> questions;

  AddQuestionsParams({
    required this.assessmentId,
    required this.questions,
  });
}
