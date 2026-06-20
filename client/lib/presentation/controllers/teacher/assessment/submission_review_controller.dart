import 'package:flutter/material.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

/// Controller for the submission review flow.
///
/// Owns ephemeral form state (essay score controllers, form errors) and
/// orchestrates provider calls for override/grade operations.
/// Consumed by both desktop and mobile submission review pages.
class SubmissionReviewController extends ChangeNotifier {
  final String submissionId;
  final TeacherAssessmentNotifier notifier;

  String? formError;
  final Map<String, TextEditingController> _essayScoreControllers = {};

  SubmissionReviewController({
    required this.submissionId,
    required this.notifier,
  });

  Map<String, TextEditingController> get essayScoreControllers =>
      _essayScoreControllers;

  void init() {
    notifier.loadSubmissionDetail(submissionId);
  }

  @override
  void dispose() {
    for (final c in _essayScoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController getOrCreateEssayController(SubmissionAnswer answer) {
    return _essayScoreControllers.putIfAbsent(
      answer.id,
      () => TextEditingController(
        text: answer.isPendingEssayGrade
            ? ''
            : answer.pointsAwarded.toStringAsFixed(
                answer.pointsAwarded % 1 == 0 ? 0 : 1,
              ),
      ),
    );
  }

  Future<void> overrideAnswer(String answerId, bool isCorrect,
      {double? points}) async {
    await notifier.overrideAnswer(
      OverrideAnswerParams(
        answerId: answerId,
        isCorrect: isCorrect,
        points: points,
      ),
    );

    if (notifier.currentError == null) {
      notifier.loadSubmissionDetail(submissionId);
    }
    _syncFormError();
  }

  Future<void> gradeEssay(String answerId, double points) async {
    await notifier.gradeEssayAnswer(
      GradeEssayParams(answerId: answerId, points: points),
    );
    _syncFormError();
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  void setFormError(String? error) {
    if (formError != error) {
      formError = error;
      notifyListeners();
    }
  }

  void _syncFormError() {
    final error = notifier.currentError;
    if (error != null) {
      formError = AppErrorMapper.toUserMessage(error);
    } else {
      formError = null;
    }
    notifyListeners();
  }
}
