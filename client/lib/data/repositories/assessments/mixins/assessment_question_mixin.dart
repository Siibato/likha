import 'package:likha/core/utils/typedef.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/data/repositories/assessments/assessment_repository_base.dart';
import 'package:likha/data/repositories/assessments/mixins/operations/question/add_questions.dart'
    as add_questions_op;
import 'package:likha/data/repositories/assessments/mixins/operations/question/update_question.dart'
    as update_question_op;
import 'package:likha/data/repositories/assessments/mixins/operations/question/delete_question.dart'
    as delete_question_op;
import 'package:likha/data/repositories/assessments/mixins/operations/question/reorder_questions.dart'
    as reorder_questions_op;

mixin AssessmentQuestionMixin on AssessmentRepositoryBase {
  @override
  ResultFuture<List<Question>> addQuestions({
    required String assessmentId,
    required List<Map<String, dynamic>> questions,
  }) =>
      add_questions_op.addQuestions(
        this,
        assessmentId: assessmentId,
        questions: questions,
      );

  @override
  ResultFuture<Question> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) =>
      update_question_op.updateQuestion(
        this,
        questionId: questionId,
        data: data,
      );

  @override
  ResultVoid deleteQuestion({required String questionId}) =>
      delete_question_op.deleteQuestion(this, questionId: questionId);

  @override
  ResultVoid reorderQuestions({
    required String assessmentId,
    required List<String> questionIds,
  }) =>
      reorder_questions_op.reorderQuestions(
        this,
        assessmentId: assessmentId,
        questionIds: questionIds,
      );
}