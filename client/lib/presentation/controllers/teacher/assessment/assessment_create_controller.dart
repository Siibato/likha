import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/question_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for the assessment creation flow.
///
/// Owns all mutable form state, draft I/O, validation, and save orchestration.
/// Both mobile and desktop pages consume this via [ListenableBuilder].
class AssessmentCreateController extends ChangeNotifier {
  final String classId;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final timeLimitController = TextEditingController(text: '30');

  DateTime openAt = DateTime.now();
  DateTime closeAt = DateTime.now().add(const Duration(days: 7));
  bool showResultsImmediately = false;
  bool isPublished = true;
  int? quarter;
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

  AssessmentCreateController({required this.classId});

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
        quarter = draft['quarter'] as int?;
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
        'quarter': quarter,
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
    quarter = null;
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

  void setQuarter(int? value) {
    quarter = value;
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

      return map;
    }).toList();
  }

  Future<Assessment?> performSave(WidgetRef ref) async {
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
      final assessment = await ref
          .read(teacherAssessmentProvider.notifier)
          .createAssessment(
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
              gradingPeriodNumber: quarter,
              component: component,
              tosId: linkedTosId,
            ),
          );

      PageLogger.instance.log('AssessmentCreateController: createAssessment returned id=${assessment?.id}');

      if (assessment == null) {
        final state = ref.read(teacherAssessmentProvider);
        formError = AppErrorMapper.toUserMessage(state.error);
        isSaving = false;
        notifyListeners();
        return null;
      }

      if (!isPublished && questions.isNotEmpty) {
        PageLogger.instance.log('AssessmentCreateController: Adding ${questions.length} questions (draft flow)');
        await ref.read(teacherAssessmentProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: assessment.id,
            questions: questionsData,
          ),
        );

        final state = ref.read(teacherAssessmentProvider);
        if (state.error != null) {
          PageLogger.instance.error('AssessmentCreateController: Error after addQuestions', Exception(state.error));
          formError = AppErrorMapper.toUserMessage(state.error);
          isSaving = false;
          notifyListeners();
          return null;
        }
      }

      PageLogger.instance.log('AssessmentCreateController: Clearing draft');
      await clearDraft();
      ref.read(teacherAssessmentProvider.notifier).clearMessages();
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
