import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/core_logger.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/usecases/clear_score_override.dart';
import 'package:likha/domain/grading/usecases/get_scores_by_item.dart';
import 'package:likha/domain/grading/usecases/save_scores.dart';
import 'package:likha/domain/grading/usecases/set_score_override.dart';
import 'package:likha/injection_container.dart';

const _unset = Object();

class GradeScoresState {
  final Map<String, List<GradeScore>> scoresByItem;
  final bool isLoading;
  final bool isGeneratingScores;
  final String? error;
  final String? successMessage;

  GradeScoresState({
    this.scoresByItem = const {},
    this.isLoading = false,
    this.isGeneratingScores = false,
    this.error,
    this.successMessage,
  });

  GradeScoresState copyWith({
    Map<String, List<GradeScore>>? scoresByItem,
    bool? isLoading,
    bool? isGeneratingScores,
    Object? error = _unset,
    Object? successMessage = _unset,
  }) {
    return GradeScoresState(
      scoresByItem: scoresByItem ?? this.scoresByItem,
      isLoading: isLoading ?? this.isLoading,
      isGeneratingScores: isGeneratingScores ?? this.isGeneratingScores,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset) ? this.successMessage : successMessage as String?,
    );
  }
}

class GradeScoresNotifier extends StateNotifier<GradeScoresState> {
  final GetScoresByItem _getScoresByItem;
  final SaveScores _saveScores;
  final SetScoreOverride _setScoreOverride;
  final ClearScoreOverride _clearScoreOverride;

  GradeScoresNotifier(
    this._getScoresByItem,
    this._saveScores,
    this._setScoreOverride,
    this._clearScoreOverride,
  ) : super(GradeScoresState());

  void setGenerating(bool value) {
    state = state.copyWith(isGeneratingScores: value);
  }

  Future<void> loadScoresForItems(List<String> gradeItemIds) async {
    state = state.copyWith(isLoading: state.scoresByItem.isEmpty, error: null);
    final Map<String, List<GradeScore>> allScores = {};

    for (final itemId in gradeItemIds) {
      final result = await _getScoresByItem(itemId);
      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
          return;
        },
        (scores) {
          allScores[itemId] = scores;
        },
      );
      if (state.error != null) return;
    }
    
    state = state.copyWith(isLoading: false, scoresByItem: allScores);
  }

  Future<void> saveScores(
    String gradeItemId,
    List<Map<String, dynamic>> scores,
  ) async {
    state = state.copyWith(error: null, successMessage: null);
    CoreLogger.instance.log('GradeScoresProvider.saveScores: gradeItemId=$gradeItemId, scoresCount=${scores.length}');
    final result = await _saveScores(gradeItemId: gradeItemId, scores: scores);
    result.fold(
      (failure) {
        CoreLogger.instance.error('GradeScoresProvider.saveScores FAILED: ${failure.message}');
        state = state.copyWith(
          error: AppErrorMapper.fromFailure(failure),
        );
      },
      (_) {
        CoreLogger.instance.log('GradeScoresProvider.saveScores: success');
        state = state.copyWith(
          successMessage: 'Scores saved',
        );
      },
    );
  }

  Future<void> setOverride(String scoreId, double overrideScore) async {
    state = state.copyWith(error: null, successMessage: null);
    final result = await _setScoreOverride(
      scoreId: scoreId,
      overrideScore: overrideScore,
    );
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        successMessage: 'Score override applied',
      ),
    );
  }

  Future<void> clearOverride(String scoreId) async {
    state = state.copyWith(error: null, successMessage: null);
    final result = await _clearScoreOverride(scoreId);
    result.fold(
      (failure) => state = state.copyWith(
        error: AppErrorMapper.fromFailure(failure),
      ),
      (_) => state = state.copyWith(
        successMessage: 'Score override cleared',
      ),
    );
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Force refresh scores from remote server (bypass cache)
  Future<void> refreshScoresFromRemote(List<String> gradeItemIds) async {
    state = state.copyWith(isLoading: true, error: null);
    final Map<String, List<GradeScore>> allScores = {};

    for (final itemId in gradeItemIds) {
      // Force remote fetch by calling repository directly
      final result = await _getScoresByItem(itemId);
      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: AppErrorMapper.fromFailure(failure));
          return;
        },
        (scores) {
          allScores[itemId] = scores;
        },
      );
      if (state.error != null) return;
    }
    
    state = state.copyWith(isLoading: false, scoresByItem: allScores);
  }
}

final gradeScoresProvider = StateNotifierProvider<GradeScoresNotifier, GradeScoresState>((ref) {
  return GradeScoresNotifier(
    sl<GetScoresByItem>(),
    sl<SaveScores>(),
    sl<SetScoreOverride>(),
    sl<ClearScoreOverride>(),
  );
});
