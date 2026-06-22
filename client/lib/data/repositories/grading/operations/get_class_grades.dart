import 'package:dartz/dartz.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/core/utils/remote_fetch.dart';
import 'package:likha/core/utils/typedef.dart';
import 'package:likha/data/datasources/local/grading/grading_local_datasource.dart';
import 'package:likha/data/datasources/remote/grading/grading_remote_datasource.dart';
import 'package:likha/data/datasources/remote/grading/operations/get_class_grades.dart' as remote_parsers;
import 'package:likha/domain/grading/entities/class_grades.dart';
import 'package:likha/data/models/grading/grade_config_model.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

import '_helpers.dart' as helpers;

ResultFuture<ClassGrades> getClassGrades(
  GradingLocalDataSource localDataSource,
  GradingRemoteDataSource remoteDataSource,
  DataEventBus dataEventBus, {
  required String classId,
  required int termNumber,
  bool skipBackgroundRefresh = false,
}) async {
  try {
    // 1. Cache-first: read config, items, scores in parallel
    final configFuture = _safeGetConfig(localDataSource, classId);
    final itemsFuture = localDataSource.getItemsByClassTerm(classId, termNumber, component: null);
    final scoresFuture = localDataSource.getScoresForClassTerm(classId, termNumber);
    final summaryFuture = _safeGetSummary(localDataSource, classId, termNumber);

    final rawConfigs = await configFuture;
    final items = await itemsFuture;
    final scoresModels = await scoresFuture;
    final summary = await summaryFuture;

    final config = _configForTerm(
      rawConfigs.map((c) => helpers.configToEntity(c as GradeConfigModel)).toList(),
      termNumber,
    );

    if (items.isEmpty) {
      throw CacheException('No cached grade items found');
    }

    final entities = items.map(helpers.itemToEntity).toList();
    final scoresByItem = _groupScoresByItem(scoresModels, entities);

    // 2. Fire non-blocking background refresh
    if (!skipBackgroundRefresh) {
      fireRemoteFetch(
        dedupKey: 'grading/classGrades/$classId/$termNumber/bg',
        remote: () => remoteDataSource.getClassGrades(
          classId: classId,
          termNumber: termNumber,
        ),
        onSuccess: (raw) async {
          final freshItems = remote_parsers.parseGradeItems(raw);
          final freshScoresByItem = remote_parsers.parseScoresByItem(raw);
          final freshConfig = remote_parsers.parseConfig(raw);
          final freshSummary = remote_parsers.parseGradeSummary(raw);

          if (await _hasChanged(localDataSource, classId, termNumber, freshItems, freshScoresByItem, freshConfig, freshSummary)) {
            // Save fresh data to local DB
            await localDataSource.saveItems(freshItems);
            for (final entry in freshScoresByItem.entries) {
              // Bug 2 fix: Skip overwriting local scores whose syncStatus is
              // pending or failed — the teacher's newer local edit must win
              // over stale remote data.
              final existingScores = await localDataSource.getScoresByItem(entry.key);
              final skipStudentIds = <String>{};
              for (final es in existingScores) {
                final status = es.syncStatus ?? 'synced';
                if (status == 'pending' || status == 'failed') {
                  skipStudentIds.add(es.studentId);
                }
              }
              final filteredScores = entry.value
                  .where((s) => !skipStudentIds.contains(s.studentId))
                  .toList();
              if (filteredScores.isNotEmpty) {
                await localDataSource.saveScores(filteredScores);
              }
            }
            if (freshConfig != null) {
              final currentConfigs = await _safeGetConfig(localDataSource, classId);
              final updatedConfigs = _mergeConfig(currentConfigs, freshConfig);
              await localDataSource.saveConfigs(updatedConfigs.map((c) => c as GradeConfigModel).toList());
            }
            if (freshSummary.isNotEmpty) {
              await localDataSource.cacheGradeSummary(classId, termNumber, freshSummary);
            }
            dataEventBus.notifyGradesChanged(classId);
          }
        },
      );
    }

    return Right(ClassGrades(
      classId: classId,
      termNumber: termNumber,
      items: entities,
      scoresByItem: scoresByItem,
      config: config,
      summary: summary,
    ));
  } on CacheException {
    // Cache miss → blocking remote fetch, then save and return
    final raw = await remoteFetch(
      dedupKey: 'grading/classGrades/$classId/$termNumber',
      remote: () => remoteDataSource.getClassGrades(
        classId: classId,
        termNumber: termNumber,
      ),
    );

    final freshItems = remote_parsers.parseGradeItems(raw);
    final freshScoresByItem = remote_parsers.parseScoresByItem(raw);
    final freshConfig = remote_parsers.parseConfig(raw);
    final freshSummary = remote_parsers.parseGradeSummary(raw);

    await localDataSource.saveItems(freshItems);
    for (final entry in freshScoresByItem.entries) {
      await localDataSource.saveScores(entry.value);
    }
    if (freshConfig != null) {
      final currentConfigs = await _safeGetConfig(localDataSource, classId);
      final updatedConfigs = _mergeConfig(currentConfigs, freshConfig);
      await localDataSource.saveConfigs(updatedConfigs.map((c) => c as GradeConfigModel).toList());
    }
    if (freshSummary.isNotEmpty) {
      await localDataSource.cacheGradeSummary(classId, termNumber, freshSummary);
    }

    final entities = freshItems.map(helpers.itemToEntity).toList();
    final scoresByItem = <String, List<GradeScore>>{};
    for (final entry in freshScoresByItem.entries) {
      scoresByItem[entry.key] = entry.value.map(helpers.scoreToEntity).toList();
    }

    return Right(ClassGrades(
      classId: classId,
      termNumber: termNumber,
      items: entities,
      scoresByItem: scoresByItem,
      config: freshConfig != null ? helpers.configToEntity(freshConfig) : null,
      summary: freshSummary.isNotEmpty ? freshSummary : null,
    ));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Future<List<dynamic>> _safeGetConfig(GradingLocalDataSource local, String classId) async {
  try {
    final configs = await local.getConfigByClass(classId);
    return configs;
  } catch (_) {
    return [];
  }
}

Future<List<Map<String, dynamic>>?> _safeGetSummary(GradingLocalDataSource local, String classId, int term) async {
  try {
    final summary = await local.getCachedGradeSummary(classId, term);
    return summary;
  } catch (_) {
    return null;
  }
}

GradeConfig? _configForTerm(List<GradeConfig> configs, int term) {
  try {
    return configs.firstWhere((c) => c.termNumber == term);
  } catch (_) {
    return configs.isNotEmpty ? configs.first : null;
  }
}

Map<String, List<GradeScore>> _groupScoresByItem(List<dynamic> scoreModels, List<GradeItem> items) {
  final map = <String, List<GradeScore>>{};
  for (final item in items) {
    map[item.id] = [];
  }
  for (final model in scoreModels) {
    final score = helpers.scoreToEntity(model);
    if (map.containsKey(score.gradeItemId)) {
      map[score.gradeItemId]!.add(score);
    }
  }
  return map;
}

Future<bool> _hasChanged(
  GradingLocalDataSource local,
  String classId,
  int term,
  List<dynamic> freshItems,
  Map<String, dynamic> freshScoresByItem,
  dynamic freshConfig,
  List<dynamic> freshSummary,
) async {
  try {
    final currentItems = await local.getItemsByClassTerm(classId, term);
    if (currentItems.length != freshItems.length) return true;

    final currentScores = await local.getScoresForClassTerm(classId, term);
    var freshScoreCount = 0;
    for (final scores in freshScoresByItem.values) {
      freshScoreCount += (scores as List).length;
    }
    if (currentScores.length != freshScoreCount) return true;

    final currentConfigs = await local.getConfigByClass(classId);
    if (freshConfig != null) {
      bool found = false;
      for (final c in currentConfigs) {
        if (c.id == freshConfig.id && c.termNumber == freshConfig.termNumber) {
          found = true;
          break;
        }
      }
      if (!found) return true;
    }

    return false;
  } catch (_) {
    return true;
  }
}

List<dynamic> _mergeConfig(List<dynamic> current, dynamic fresh) {
  final updated = <dynamic>[];
  var replaced = false;
  for (final c in current) {
    if (c.termNumber == fresh.termNumber) {
      updated.add(fresh);
      replaced = true;
    } else {
      updated.add(c);
    }
  }
  if (!replaced) updated.add(fresh);
  return updated;
}
