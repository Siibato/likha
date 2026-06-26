import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/domain/assessments/entities/question_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-competency progress row.
class TosCompetencyProgress {
  final String competencyId;
  final String label;
  final Map<String, int> required;
  final Map<String, int> added;
  final Map<String, int> remaining;
  final bool isComplete;

  const TosCompetencyProgress({
    required this.competencyId,
    required this.label,
    required this.required,
    required this.added,
    required this.remaining,
    required this.isComplete,
  });
}

/// Holds progress data computed from the linked TOS vs. question drafts.
class TosLevelSummary {
  final Map<String, int> required;
  final Map<String, int> added;
  final Map<String, int> remaining;
  final bool isComplete;
  final List<TosCompetencyProgress> competencyProgress;

  const TosLevelSummary({
    required this.required,
    required this.added,
    required this.remaining,
    required this.isComplete,
    this.competencyProgress = const [],
  });
}

/// Controller for the assessment creation flow.
///
/// Owns all mutable form state, draft I/O, validation, and save orchestration.
/// Both mobile and desktop pages consume this via [ListenableBuilder].
class AssessmentCreateController extends ChangeNotifier {
  final String classId;
  final AssessmentListNotifier listNotifier;
  final AssessmentDetailNotifier detailNotifier;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final timeLimitController = TextEditingController(text: '30');

  DateTime openAt = DateTime.now();
  DateTime closeAt = DateTime.now().add(const Duration(days: 7));
  bool showResultsImmediately = false;
  bool isPublished = true;
  int? termNumber;
  String? component;
  bool isDepartmentalExam = false;
  String? linkedTosId;

  final List<QuestionDraft> questions = [];
  bool isQuestionReorderMode = false;

  bool isAddingQuestion = false;
  int? editingQuestionIndex;

  bool isSaving = false;
  bool draftLoaded = false;
  String? formError;

  Timer? _autoSaveTimer;

  AssessmentCreateController({required this.classId, required this.listNotifier, required this.detailNotifier});

  String get _draftKey => 'assessment_draft_$classId';

  Future<void> init() async {
    await _loadDraft();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey);
      if (draftJson != null) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        titleController.text = draft['title'] as String? ?? '';
        descriptionController.text = draft['description'] as String? ?? '';
        timeLimitController.text = draft['timeLimitMinutes'].toString();
        openAt = DateTime.parse(
          draft['openAt'] as String? ?? DateTime.now().toIso8601String(),
        );
        closeAt = DateTime.parse(
          draft['closeAt'] as String? ??
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        );
        showResultsImmediately = draft['showResultsImmediately'] as bool? ?? false;
        isPublished = draft['isPublished'] as bool? ?? true;
        termNumber = draft['termNumber'] as int?;
        component = draft['component'] as String?;
        isDepartmentalExam = draft['isDepartmentalExam'] as bool? ?? false;
        linkedTosId = draft['linkedTosId'] as String?;

        final qList = draft['questions'] as List?;
        if (qList != null) {
          questions.clear();
          for (final q in qList) {
            questions.add(QuestionDraft.fromJson(q as Map<String, dynamic>));
          }
        }
        draftLoaded = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> persistDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'title': titleController.text,
        'description': descriptionController.text,
        'timeLimitMinutes': int.tryParse(timeLimitController.text) ?? 30,
        'openAt': openAt.toIso8601String(),
        'closeAt': closeAt.toIso8601String(),
        'showResultsImmediately': showResultsImmediately,
        'isPublished': isPublished,
        'termNumber': termNumber,
        'component': component,
        'isDepartmentalExam': isDepartmentalExam,
        'linkedTosId': linkedTosId,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
      await prefs.setString(_draftKey, jsonEncode(draft));
    } catch (_) {}
  }

  Future<void> saveDraftWithFeedback() async {
    await persistDraft();
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  Future<void> discardDraft() async {
    await clearDraft();
    draftLoaded = false;
    titleController.clear();
    descriptionController.clear();
    timeLimitController.text = '30';
    openAt = DateTime.now();
    closeAt = DateTime.now().add(const Duration(days: 7));
    showResultsImmediately = false;
    isPublished = true;
    termNumber = null;
    component = null;
    isDepartmentalExam = false;
    linkedTosId = null;
    questions.clear();
    isAddingQuestion = false;
    editingQuestionIndex = null;
    isQuestionReorderMode = false;
    formError = null;
    notifyListeners();
  }

  void scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), persistDraft);
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

  void setIsPublished(bool value) {
    isPublished = value;
    formError = null;
    notifyListeners();
  }

  void setTermNumber(int? value) {
    termNumber = value;
    formError = null;
    notifyListeners();
  }

  void setComponent(String? value) {
    component = value;
    isDepartmentalExam = false;
    formError = null;
    notifyListeners();
  }

  void setIsDepartmentalExam(bool value) {
    isDepartmentalExam = value;
    formError = null;
    notifyListeners();
  }

  void setLinkedTosId(String? value) {
    linkedTosId = value;
    formError = null;
    notifyListeners();
  }

  void clearFormError() {
    if (formError != null) {
      formError = null;
      notifyListeners();
    }
  }

  void addQuestion() {
    questions.add(QuestionDraft());
    scheduleAutoSave();
    notifyListeners();
  }

  void removeQuestion(int index) {
    questions.removeAt(index);
    scheduleAutoSave();
    notifyListeners();
  }

  void confirmAddQuestion(QuestionDraft draft) {
    questions.add(draft);
    isAddingQuestion = false;
    scheduleAutoSave();
    notifyListeners();
  }

  void saveEdit(int index, QuestionDraft draft) {
    questions[index] = draft;
    editingQuestionIndex = null;
    scheduleAutoSave();
    notifyListeners();
  }

  void enterQuestionReorderMode() {
    isQuestionReorderMode = true;
    notifyListeners();
  }

  void exitQuestionReorderMode() {
    isQuestionReorderMode = false;
    scheduleAutoSave();
    notifyListeners();
  }

  void reorderQuestion(int fromIndex, int toIndex) {
    final q = questions.removeAt(fromIndex);
    questions.insert(toIndex, q);
    scheduleAutoSave();
    notifyListeners();
  }

  void setIsAddingQuestion(bool value) {
    isAddingQuestion = value;
    notifyListeners();
  }

  void setEditingQuestionIndex(int? value) {
    editingQuestionIndex = value;
    notifyListeners();
  }

  String? validateAll() {
    final timeLimit = int.tryParse(timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      return 'Please enter a valid time limit';
    }

    if (closeAt.isBefore(openAt)) {
      return 'Close date must be after open date';
    }

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (q.questionText.trim().isEmpty) {
        return 'Question ${i + 1} text is empty';
      }
      if (q.type == 'multiple_choice' && q.choices.length < 2) {
        return 'Question ${i + 1} needs at least 2 choices';
      }
      if (q.type == 'multiple_choice' && !q.choices.any((c) => c.isCorrect)) {
        return 'Question ${i + 1} needs at least one correct choice';
      }
      if (q.type == 'identification' && q.acceptableAnswers.isEmpty) {
        return 'Question ${i + 1} needs at least one acceptable answer';
      }
      if (q.type == 'enumeration' && q.enumerationItems.isEmpty) {
        return 'Question ${i + 1} needs at least one enumeration item';
      }
    }

    return null;
  }

  /// Computes how many questions of each level are required by the TOS,
  /// how many have been tagged so far, and how many remain.
  /// If [competencies] is provided, also computes per-competency progress.
  TosLevelSummary computeTosProgress(
    TableOfSpecifications tos, {
    List<TosCompetency> competencies = const [],
  }) {
    final total = tos.totalItems;
    final isBlooms = tos.classificationMode == 'blooms';
    final totalDays = competencies.fold<int>(0, (s, c) => s + c.timeUnitsTaught);

    Map<String, int> _levelRequired(int targetItems) => isBlooms
        ? {
            'remembering': (targetItems * tos.rememberingPercentage / 100).round(),
            'understanding': (targetItems * tos.understandingPercentage / 100).round(),
            'applying': (targetItems * tos.applyingPercentage / 100).round(),
            'analyzing': (targetItems * tos.analyzingPercentage / 100).round(),
            'evaluating': (targetItems * tos.evaluatingPercentage / 100).round(),
            'creating': (targetItems * tos.creatingPercentage / 100).round(),
          }
        : {
            'easy': (targetItems * tos.easyPercentage / 100).round(),
            'medium': (targetItems * tos.mediumPercentage / 100).round(),
            'hard': (targetItems * tos.hardPercentage / 100).round(),
          };

    Map<String, int> _levelRequiredFromCompetency(TosCompetency c, int targetItems) {
      if (isBlooms) {
        return {
          'remembering': c.rememberingCount ?? (targetItems * tos.rememberingPercentage / 100).round(),
          'understanding': c.understandingCount ?? (targetItems * tos.understandingPercentage / 100).round(),
          'applying': c.applyingCount ?? (targetItems * tos.applyingPercentage / 100).round(),
          'analyzing': c.analyzingCount ?? (targetItems * tos.analyzingPercentage / 100).round(),
          'evaluating': c.evaluatingCount ?? (targetItems * tos.evaluatingPercentage / 100).round(),
          'creating': c.creatingCount ?? (targetItems * tos.creatingPercentage / 100).round(),
        };
      }
      return {
        'easy': c.easyCount ?? (targetItems * tos.easyPercentage / 100).round(),
        'medium': c.mediumCount ?? (targetItems * tos.mediumPercentage / 100).round(),
        'hard': c.hardCount ?? (targetItems * tos.hardPercentage / 100).round(),
      };
    }

    // Overall totals
    final Map<String, int> required = _levelRequired(total);
    final Map<String, int> added = {for (final k in required.keys) k: 0};

    for (final q in questions) {
      final tag = isBlooms ? q.cognitiveLevel : q.difficulty;
      if (tag != null && added.containsKey(tag)) {
        added[tag] = added[tag]! + 1;
      }
    }

    final Map<String, int> remaining = {
      for (final k in required.keys)
        k: (required[k]! - added[k]!).clamp(0, required[k]!),
    };

    final isComplete = remaining.values.every((v) => v == 0);

    // Per-competency progress
    final List<TosCompetencyProgress> competencyProgress = [];
    if (competencies.isNotEmpty) {
      for (final comp in competencies) {
        final weight = totalDays > 0 ? comp.timeUnitsTaught / totalDays : 0.0;
        final targetItems = (weight * total).round();
        final compRequired = _levelRequiredFromCompetency(comp, targetItems);
        final compAdded = {for (final k in compRequired.keys) k: 0};

        for (final q in questions) {
          if (q.tosCompetencyId != comp.id) continue;
          final tag = isBlooms ? q.cognitiveLevel : q.difficulty;
          if (tag != null && compAdded.containsKey(tag)) {
            compAdded[tag] = compAdded[tag]! + 1;
          }
        }

        final compRemaining = {
          for (final k in compRequired.keys)
            k: (compRequired[k]! - compAdded[k]!).clamp(0, compRequired[k]!),
        };

        final compLabel = comp.competencyCode != null
            ? '${comp.competencyCode} — ${comp.competencyText}'
            : comp.competencyText;

        competencyProgress.add(TosCompetencyProgress(
          competencyId: comp.id,
          label: compLabel,
          required: compRequired,
          added: compAdded,
          remaining: compRemaining,
          isComplete: compRemaining.values.every((v) => v == 0),
        ));
      }
    }

    return TosLevelSummary(
      required: required,
      added: added,
      remaining: remaining,
      isComplete: isComplete,
      competencyProgress: competencyProgress,
    );
  }

  List<Map<String, dynamic>> buildQuestionsData() {
    return questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final map = <String, dynamic>{
        'question_type': q.type,
        'question_text': q.questionText.trim(),
        'points': q.points,
        'order_index': i,
      };

      if (q.type == 'multiple_choice') {
        map['is_multi_select'] = q.isMultiSelect;
        map['choices'] = q.choices.asMap().entries.map((ce) {
          return {
            'choice_text': ce.value.text.trim(),
            'is_correct': ce.value.isCorrect,
            'order_index': ce.key,
          };
        }).toList();
      } else if (q.type == 'identification') {
        map['correct_answers'] = q.acceptableAnswers
            .where((a) => a.trim().isNotEmpty)
            .map((a) => a.trim())
            .toList();
      } else if (q.type == 'enumeration') {
        map['enumeration_items'] = q.enumerationItems.asMap().entries.map((ie) {
          return {
            'order_index': ie.key,
            'acceptable_answers': ie.value.answers
                .where((a) => a.trim().isNotEmpty)
                .map((a) => a.trim())
                .toList(),
          };
        }).toList();
      }

      if (q.difficulty != null) map['difficulty'] = q.difficulty;
      if (q.cognitiveLevel != null) map['cognitive_level'] = q.cognitiveLevel;
      if (q.tosCompetencyId != null) map['tos_competency_id'] = q.tosCompetencyId;

      return map;
    }).toList();
  }

  Future<Assessment?> performSave() async {
    final error = validateAll();
    if (error != null) {
      formError = error;
      notifyListeners();
      return null;
    }

    isSaving = true;
    formError = null;
    notifyListeners();

    try {
      PageLogger.instance.log('AssessmentCreateController.performSave: Starting');
      final questionsData = buildQuestionsData();

      PageLogger.instance.log('AssessmentCreateController: calling createAssessment');
      final assessment = await listNotifier.createAssessment(
            CreateAssessmentParams(
              classId: classId,
              title: titleController.text.trim(),
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              timeLimitMinutes: int.parse(timeLimitController.text.trim()),
              openAt: formatDateTimeForApi(openAt),
              closeAt: formatDateTimeForApi(closeAt),
              showResultsImmediately: showResultsImmediately,
              isPublished: isPublished,
              questions: isPublished ? questionsData : null,
              termNumber: termNumber,
              component: component,
              tosId: linkedTosId,
            ),
          );

      PageLogger.instance.log('AssessmentCreateController: createAssessment returned id=${assessment?.id}');

      if (assessment == null) {
        formError = AppErrorMapper.toUserMessage(listNotifier.currentError);
        isSaving = false;
        notifyListeners();
        return null;
      }

      if (!isPublished && questions.isNotEmpty) {
        PageLogger.instance.log('AssessmentCreateController: Adding ${questions.length} questions (draft flow)');
        await detailNotifier.addQuestions(
          AddQuestionsParams(
            assessmentId: assessment.id,
            questions: questionsData,
          ),
        );

        if (detailNotifier.currentError != null) {
          PageLogger.instance.error('AssessmentCreateController: Error after addQuestions', Exception(detailNotifier.currentError));
          formError = AppErrorMapper.toUserMessage(detailNotifier.currentError);
          isSaving = false;
          notifyListeners();
          return null;
        }
      }

      PageLogger.instance.log('AssessmentCreateController: Clearing draft');
      await clearDraft();
      listNotifier.clearMessages();
      detailNotifier.clearMessages();
      isSaving = false;
      notifyListeners();
      return assessment;
    } catch (e) {
      PageLogger.instance.error('AssessmentCreateController: Exception caught', e);
      formError = 'An error occurred: $e';
      isSaving = false;
      notifyListeners();
      return null;
    }
  }
}
