import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';
import 'operations/question/update_question_locally.dart';
import 'operations/question/delete_question_locally.dart';
import 'operations/question/get_cached_question.dart';
import 'operations/question/update_question_id.dart';
import 'operations/question/update_choice_ids.dart';
import 'operations/question/update_correct_answer_ids.dart';

mixin QuestionDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> updateQuestionLocally({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
  }) async {
    return updateQuestionLocallyOp(localDatabase, questionId, updates, isOfflineMutation);
  }

  @override
  Future<void> deleteQuestionLocally({required String questionId}) async {
    return deleteQuestionLocallyOp(localDatabase, questionId);
  }

  @override
  Future<QuestionModel?> getCachedQuestion(String questionId) async {
    return getCachedQuestionOp(localDatabase, questionId);
  }

  @override
  Future<void> updateQuestionId({required String localId, required String serverId}) async {
    return updateQuestionIdOp(localDatabase, localId, serverId);
  }

  @override
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) async {
    return updateChoiceIdsOp(localDatabase, questionId, idMapping);
  }

  @override
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) async {
    return updateCorrectAnswerIdsOp(localDatabase, questionId, idMapping);
  }
}
