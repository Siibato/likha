import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/usecases/add_questions.dart';
import 'package:likha/domain/assessments/usecases/create_assessment.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_draft.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_details_step.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_questions_step.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_review_step.dart';

class CreateAssessmentPage extends ConsumerStatefulWidget {
  final String classId;

  const CreateAssessmentPage({super.key, required this.classId});

  @override
  ConsumerState<CreateAssessmentPage> createState() =>
      _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends ConsumerState<CreateAssessmentPage> {
  int _currentStep = 0;

  // Step 1: Assessment details
  final _detailsFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');
  DateTime _openAt = DateTime.now();
  DateTime _closeAt = DateTime.now().add(const Duration(days: 7));
  bool _showResultsImmediately = false;

  final List<QuestionDraft> _questions = [];

  String? _createdAssessmentId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  String _formatDateTimeForApi(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  Future<void> _handleCreateAssessment() async {
    if (!_detailsFormKey.currentState!.validate()) return;

    final timeLimit = int.tryParse(_timeLimitController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      _showErrorSnackBar('Please enter a valid time limit');
      return;
    }

    if (_closeAt.isBefore(_openAt)) {
      _showErrorSnackBar('Close date must be after open date');
      return;
    }

    await ref.read(assessmentProvider.notifier).createAssessment(
          CreateAssessmentParams(
            classId: widget.classId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            timeLimitMinutes: timeLimit,
            openAt: _formatDateTimeForApi(_openAt),
            closeAt: _formatDateTimeForApi(_closeAt),
            showResultsImmediately: _showResultsImmediately,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentProvider);
    if (state.currentAssessment != null && state.error == null) {
      _createdAssessmentId = state.currentAssessment!.id;
      setState(() => _currentStep = 1);
      _showSuccessSnackBar('Assessment created. Now add questions.');
      ref.read(assessmentProvider.notifier).clearMessages();
    } else if (state.error != null) {
      _showErrorSnackBar(state.error!);
      ref.read(assessmentProvider.notifier).clearMessages();
    }
  }

  Future<void> _handleSaveQuestions() async {
    if (_questions.isEmpty) {
      _showErrorSnackBar('Please add at least one question');
      return;
    }

    // Validation
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        _showErrorSnackBar('Question ${i + 1} text is empty');
        return;
      }
      if (q.type == 'multiple_choice' && q.choices.length < 2) {
        _showErrorSnackBar('Question ${i + 1} needs at least 2 choices');
        return;
      }
      if (q.type == 'multiple_choice' && !q.choices.any((c) => c.isCorrect)) {
        _showErrorSnackBar('Question ${i + 1} needs at least one correct choice');
        return;
      }
      if (q.type == 'identification' && q.acceptableAnswers.isEmpty) {
        _showErrorSnackBar('Question ${i + 1} needs at least one acceptable answer');
        return;
      }
      if (q.type == 'enumeration' && q.enumerationItems.isEmpty) {
        _showErrorSnackBar('Question ${i + 1} needs at least one enumeration item');
        return;
      }
    }

    final questionsData = _questions.asMap().entries.map((entry) {
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

    await ref.read(assessmentProvider.notifier).addQuestions(
          AddQuestionsParams(
            assessmentId: _createdAssessmentId!,
            questions: questionsData,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentProvider);
    if (state.error != null) {
      _showErrorSnackBar(state.error!);
      ref.read(assessmentProvider.notifier).clearMessages();
    } else {
      setState(() => _currentStep = 2);
      ref.read(assessmentProvider.notifier).clearMessages();
    }
  }

  void _handleFinish() {
    _showSuccessSnackBar('Assessment saved as draft');
    Navigator.pop(context, true);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          _currentStep == 0
              ? 'Create Assessment'
              : _currentStep == 1
                  ? 'Add Questions'
                  : 'Review',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: null,
        onStepCancel: null,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Assessment Details'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: AssessmentDetailsStep(
              formKey: _detailsFormKey,
              titleController: _titleController,
              descriptionController: _descriptionController,
              timeLimitController: _timeLimitController,
              openAt: _openAt,
              closeAt: _closeAt,
              showResultsImmediately: _showResultsImmediately,
              isLoading: assessmentState.isLoading,
              onOpenAtChanged: (dt) => setState(() => _openAt = dt),
              onCloseAtChanged: (dt) => setState(() => _closeAt = dt),
              onShowResultsChanged: (value) =>
                  setState(() => _showResultsImmediately = value),
              onCreateAssessment: _handleCreateAssessment,
            ),
          ),
          Step(
            title: const Text('Questions'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: AssessmentQuestionsStep(
              questions: _questions,
              isLoading: assessmentState.isLoading,
              onAddQuestion: () => setState(() => _questions.add(QuestionDraft())),
              onRemoveQuestion: (index) => setState(() => _questions.removeAt(index)),
              onQuestionsChanged: () => setState(() {}),
              onSaveQuestions: _handleSaveQuestions,
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: AssessmentReviewStep(
              title: _titleController.text,
              description: _descriptionController.text,
              timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 0,
              openAt: _openAt,
              closeAt: _closeAt,
              showResultsImmediately: _showResultsImmediately,
              questions: _questions,
              onFinish: _handleFinish,
            ),
          ),
        ],
      ),
    );
  }
}