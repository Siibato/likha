import 'package:flutter/widgets.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/update_assessment.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

/// Controller for the assessment detail flow.
///
/// Owns mutable page state (reorder mode, grading edits, form errors).
/// Both mobile and desktop pages consume this via [ListenableBuilder].
class AssessmentDetailController extends ChangeNotifier {
  final String assessmentId;
  final TeacherAssessmentNotifier notifier;

  bool isQuestionReorderMode = false;
  List<Question> questionReorderBuffer = [];
  final Map<String, int> questionAnimatingIndices = {};
  String? formError;
  int? editingGradingPeriod;
  String? editingComponent;
  bool isEditingGrading = false;

  AssessmentDetailController({
    required this.assessmentId,
    required this.notifier,
  });

  // ── Question reorder ──

  void enterQuestionReorderMode(List<Question> questions) {
    isQuestionReorderMode = true;
    questionReorderBuffer = List.from(questions);
    notifyListeners();
  }

  void cancelQuestionReorderMode() {
    isQuestionReorderMode = false;
    questionReorderBuffer = [];
    questionAnimatingIndices.clear();
    notifyListeners();
  }

  Future<void> exitQuestionReorderMode() async {
    isQuestionReorderMode = false;
    questionAnimatingIndices.clear();
    notifyListeners();

    final questionIds = questionReorderBuffer.map((q) => q.id).toList();
    await notifier.reorderAllQuestions(
      assessmentId: assessmentId,
      questionIds: questionIds,
      orderedQuestions: questionReorderBuffer,
    );
    questionReorderBuffer = [];
  }

  void animateQuestionReorder(int fromIndex, int toIndex) {
    questionAnimatingIndices.clear();
    for (int i = 0; i < questionReorderBuffer.length; i++) {
      questionAnimatingIndices[questionReorderBuffer[i].id] = i;
    }

    final q = questionReorderBuffer.removeAt(fromIndex);
    questionReorderBuffer.insert(toIndex, q);
    notifyListeners();
  }

  void clearAnimatingIndices() {
    questionAnimatingIndices.clear();
  }

  // ── Grading settings ──

  void startEditingGrading(Assessment assessment) {
    editingGradingPeriod = assessment.termNumber;
    editingComponent = assessment.component;
    isEditingGrading = true;
    formError = null;
    notifyListeners();
  }

  void cancelEditingGrading() {
    editingGradingPeriod = null;
    editingComponent = null;
    isEditingGrading = false;
    formError = null;
    notifyListeners();
  }

  Future<void> saveGradingSettings() async {
    isEditingGrading = false;
    notifyListeners();

    try {
      await notifier.updateAssessment(
        UpdateAssessmentParams(
          assessmentId: assessmentId,
          termNumber: editingGradingPeriod,
          component: editingComponent,
        ),
      );

      editingGradingPeriod = null;
      editingComponent = null;
    } catch (e) {
      isEditingGrading = true;
      formError = 'Failed to update grading settings';
      notifyListeners();
    }
  }

  void setEditingGradingPeriod(int? value) {
    editingGradingPeriod = value;
    notifyListeners();
  }

  void setEditingComponent(String? value) {
    editingComponent = value;
    notifyListeners();
  }

  // ── Form error ──

  void setFormError(String? error) {
    formError = error;
    notifyListeners();
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }
}
