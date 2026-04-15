import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class OverrideAnswer {
  final AssessmentRepository _repository;

  OverrideAnswer(this._repository);

  ResultFuture<SubmissionAnswer> call(OverrideAnswerParams params) {
    return _repository.overrideAnswer(
      answerId: params.answerId,
      isCorrect: params.isCorrect,
      points: params.points,
    );
  }
}

class OverrideAnswerParams {
  final String answerId;
  final bool isCorrect;
  final double? points;

  OverrideAnswerParams({
    required this.answerId,
    required this.isCorrect,
    this.points,
  });
}
