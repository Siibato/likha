import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/repositories/assessment_repository.dart';

class GradeEssay {
  final AssessmentRepository _repository;

  GradeEssay(this._repository);

  ResultFuture<SubmissionAnswer> call(GradeEssayParams params) {
    return _repository.gradeEssayAnswer(
      answerId: params.answerId,
      points: params.points,
    );
  }
}

class GradeEssayParams {
  final String answerId;
  final double points;

  GradeEssayParams({required this.answerId, required this.points});
}
