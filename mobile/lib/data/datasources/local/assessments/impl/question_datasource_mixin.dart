import 'dart:convert';
import 'package:likha/core/errors/exceptions.dart';
import '../assessment_local_datasource_base.dart';

mixin QuestionDataSourceMixin on AssessmentLocalDataSourceBase {
  /// Transform API keys (choices, correct_answers, enumeration_items) to SQLite columns
  static Map<String, dynamic> _toSqliteColumns(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    if (result.containsKey('choices')) {
      result['choices_json'] = jsonEncode(result.remove('choices'));
    }
    if (result.containsKey('correct_answers')) {
      result['correct_answers_json'] = jsonEncode(result.remove('correct_answers'));
    }
    if (result.containsKey('enumeration_items')) {
      result['enumeration_items_json'] = jsonEncode(result.remove('enumeration_items'));
    }
    return result;
  }

  @override
  Future<void> updateQuestionLocally({
    required String questionId,
    required Map<String, dynamic> updates,
    bool isOfflineMutation = true,
  }) async {
    try {
      final db = await localDatabase.database;
      final sqlUpdates = _toSqliteColumns(Map.from(updates));
      sqlUpdates['updated_at'] = DateTime.now().toIso8601String();
      sqlUpdates['is_offline_mutation'] = isOfflineMutation ? 1 : 0;
      sqlUpdates['sync_status'] = isOfflineMutation ? 'pending' : 'synced';
      await db.update('questions', sqlUpdates, where: 'id = ?', whereArgs: [questionId]);
    } catch (e) {
      throw CacheException('Failed to update question locally: $e');
    }
  }

  @override
  Future<void> deleteQuestionLocally({required String questionId}) async {
    try {
      final db = await localDatabase.database;
      await db.update(
        'questions',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'is_offline_mutation': 1,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to delete question locally: $e');
    }
  }

  @override
  Future<void> updateQuestionId({required String localId, required String serverId}) async {
    try {
      final db = await localDatabase.database;
      await db.update('questions', {'id': serverId}, where: 'id = ?', whereArgs: [localId]);
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
      final result = await db.query('questions', columns: ['choices_json'], where: 'id = ?', whereArgs: [questionId]);
      if (result.isEmpty) return;
      final choicesJson = result.first['choices_json'] as String?;
      if (choicesJson == null || choicesJson.isEmpty) return;

      final choices = jsonDecode(choicesJson) as List<dynamic>;
      for (final choice in choices) {
        final oldId = choice['id'] as String?;
        if (oldId != null && idMapping.containsKey(oldId)) choice['id'] = idMapping[oldId];
      }
      await db.update(
        'questions',
        {'choices_json': jsonEncode(choices), 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [questionId],
      );
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
      final result = await db.query('questions', columns: ['correct_answers_json'], where: 'id = ?', whereArgs: [questionId]);
      if (result.isEmpty) return;
      final answersJson = result.first['correct_answers_json'] as String?;
      if (answersJson == null || answersJson.isEmpty) return;

      final answers = jsonDecode(answersJson) as List<dynamic>;
      for (final answer in answers) {
        final oldId = answer['id'] as String?;
        if (oldId != null && idMapping.containsKey(oldId)) answer['id'] = idMapping[oldId];
      }
      await db.update(
        'questions',
        {'correct_answers_json': jsonEncode(answers), 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [questionId],
      );
    } catch (e) {
      throw CacheException('Failed to update correct answer IDs: $e');
    }
  }
}