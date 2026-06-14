import 'package:flutter/widgets.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

/// Controller for the assessment edit flow.
///
/// Owns all mutable form state, validation, and save orchestration.
/// Both mobile and desktop pages consume this via [ListenableBuilder].
class AssessmentEditController extends ChangeNotifier {
  final TeacherAssessmentNotifier notifier;

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController timeLimitController;

  DateTime openAt;
  DateTime closeAt;
  bool showResultsImmediately;

  String? formError;

  AssessmentEditController({
    required Assessment initial,
    required this.notifier,
  })  : titleController = TextEditingController(text: initial.title),
        descriptionController =
            TextEditingController(text: initial.description ?? ''),
        timeLimitController = TextEditingController(
          text: initial.timeLimitMinutes.toString(),
        ),
        openAt = initial.openAt,
        closeAt = initial.closeAt,
        showResultsImmediately = initial.showResultsImmediately;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    timeLimitController.dispose();
    super.dispose();
  }

  void setOpenAt(DateTime value) {
    openAt = value;
    formError = null;
    notifyListeners();
  }

  void setCloseAt(DateTime value) {
    closeAt = value;
    formError = null;
    notifyListeners();
  }

  void setShowResultsImmediately(bool value) {
    showResultsImmediately = value;
    formError = null;
    notifyListeners();
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  Future<bool> performSave(String assessmentId) async {
    final timeLimit = int.tryParse(timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      formError = 'Please enter a valid time limit';
      notifyListeners();
      return false;
    }

    if (closeAt.isBefore(openAt)) {
      formError = 'Close date must be after open date';
      notifyListeners();
      return false;
    }

    await notifier.updateAssessment(
      UpdateAssessmentParams(
        assessmentId: assessmentId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        timeLimitMinutes: timeLimit,
        openAt: formatDateTimeForApi(openAt),
        closeAt: formatDateTimeForApi(closeAt),
        showResultsImmediately: showResultsImmediately,
      ),
    );

    if (notifier.currentError != null) {
      formError = AppErrorMapper.toUserMessage(notifier.currentError);
      notifier.clearMessages();
      notifyListeners();
      return false;
    }

    notifier.clearMessages();
    return true;
  }
}
