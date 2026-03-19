import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';

mixin QuestionDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> updateQuestionLocally({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
  }) async {
    try {
      final db = await localDatabase.database;
      updates[CommonCols.updatedAt] = DateTime.now().toIso8601String();
      updates[CommonCols.needsSync] = isOfflineMutation ? 1 : 0;
      await db.update(DbTables.assessmentQuestions, updates, where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL', whereArgs: [questionId]);
    } catch (e) {
      throw CacheException('Failed to update question locally: $e');
    }
  }

  @override
  Future<void> deleteQuestionLocally({required String questionId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        DbTables.assessmentQuestions,
        {
          CommonCols.deletedAt: DateTime.now().toIso8601String(),
          CommonCols.updatedAt: DateTime.now().toIso8601String(),
          CommonCols.needsSync: 1,
        },
        where: '${CommonCols.id} = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to delete question locally: $e');
    }
  }

  @override
  Future<QuestionModel?> getCachedQuestion(String questionId) async {
    try {
      final db = await localDatabase.database;
      final rows = await db.query(
        DbTables.assessmentQuestions,
        where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
        whereArgs: [questionId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return QuestionModel.fromMap(rows.first);
    } catch (e) {
      throw CacheException('Failed to get cached question: $e');
    }
  }

  @override
  Future<void> updateQuestionId({required String localId, required String serverId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(DbTables.assessmentQuestions, {CommonCols.id: serverId}, where: '${CommonCols.id} = ?', whereArgs: [localId]);
    } catch (e) {
      throw CacheException('Failed to update question ID: $e');
    }
  }

  @override
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) async {
    try {
      final db = await localDatabase.database;
      // Update choice IDs in the question_choices table
      for (final entry in idMapping.entries) {
        await db.update(
          DbTables.questionChoices,
          {CommonCols.id: entry.value},
          where: '${CommonCols.id} = ?',
          whereArgs: [entry.key],
        );
      }
    } catch (e) {
      throw CacheException('Failed to update choice IDs: $e');
    }
  }

  @override
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  }) async {
    try {
      final db = await localDatabase.database;
      // Update answer IDs in the answer_key_acceptable_answers table
      for (final entry in idMapping.entries) {
        await db.update(
          DbTables.answerKeyAcceptableAnswers,
          {CommonCols.id: entry.value},
          where: '${CommonCols.id} = ?',
          whereArgs: [entry.key],
        );
      }
    } catch (e) {
      throw CacheException('Failed to update correct answer IDs: $e');
    }
  }
}
