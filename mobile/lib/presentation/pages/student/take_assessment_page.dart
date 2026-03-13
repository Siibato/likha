import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/domain/assessments/usecases/save_answers.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_timer_badge.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_question_card.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_submit_section.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_dialogs.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class TakeAssessmentPage extends ConsumerStatefulWidget {
  final String assessmentId;
  final int timeLimitMinutes;

  const TakeAssessmentPage({
    super.key,
    required this.assessmentId,
    required this.timeLimitMinutes,
  });

  @override
  ConsumerState<TakeAssessmentPage> createState() =>
      _TakeAssessmentPageState();
}

class _TakeAssessmentPageState extends ConsumerState<TakeAssessmentPage> {
  Timer? _countdownTimer;
  Timer? _autoSaveTimer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  bool _hasStarted = false;

  List<StudentQuestion> _questions = [];
  String? _submissionId;

  final Map<String, String> _textAnswers = {};
  final Map<String, Set<String>> _selectedChoices = {};
  final Map<String, Map<int, String>> _enumerationAnswers = {};

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Map<int, TextEditingController>> _enumControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAssessment();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoSaveTimer?.cancel();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final controllerMap in _enumControllers.values) {
      for (final controller in controllerMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _startAssessment() async {
    // Read current user from auth state
    final user = ref.read(authProvider).user;
    if (user == null) return;

    await ref
        .read(assessmentProvider.notifier)
        .startAssessment(
          widget.assessmentId,
          user.id,
          user.fullName,
          user.username,
        );

    final state = ref.read(assessmentProvider);
    if (state.startResult != null) {
      final startResult = state.startResult!;
      _submissionId = startResult.submissionId;

      try {
        final parsedQuestions = startResult.questions
            .map((q) =>
                StudentQuestionModel.fromJson(q as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        final elapsed =
            sl<ServerClockService>().now().difference(startResult.startedAt).inSeconds;
        final totalSeconds = widget.timeLimitMinutes * 60;
        final remaining = totalSeconds - elapsed;

        if (remaining <= 0) {
          if (mounted) {
            _autoSubmit();
          }
          return;
        }

        setState(() {
          _questions = parsedQuestions;
          _remainingSeconds = remaining;
          _hasStarted = true;
        });

        _initializeAnswerState();
        _startCountdown();
        _startAutoSave();
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasStarted = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.showErrorSnackBar('Failed to load questions. Please try again.');
            }
          });
        }
        return;
      }
    }
  }

  void _initializeAnswerState() {
    for (final question in _questions) {
      if (question.questionType == 'multiple_choice') {
        _selectedChoices[question.id] = {};
      } else if (question.questionType == 'identification') {
        final controller = TextEditingController();
        _textControllers[question.id] = controller;
        _textAnswers[question.id] = '';
      } else if (question.questionType == 'enumeration') {
        final count = question.enumerationCount ?? 0;
        _enumerationAnswers[question.id] = {};
        _enumControllers[question.id] = {};
        for (int i = 0; i < count; i++) {
          final controller = TextEditingController();
          _enumControllers[question.id]![i] = controller;
          _enumerationAnswers[question.id]![i] = '';
        }
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoSubmit();
      }
    });
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || _submissionId == null) {
        timer.cancel();
        return;
      }
      _saveAnswers();
    });
  }

  List<Map<String, dynamic>> _buildAnswersPayload() {
    final List<Map<String, dynamic>> answers = [];

    for (final question in _questions) {
      final answer = <String, dynamic>{'question_id': question.id};

      switch (question.questionType) {
        case 'multiple_choice':
          final selected = _selectedChoices[question.id] ?? {};
          answer['selected_choice_ids'] = selected.toList();
          break;
        case 'identification':
          answer['answer_text'] = _textAnswers[question.id] ?? '';
          break;
        case 'enumeration':
          final enumAnswers = _enumerationAnswers[question.id] ?? {};
          answer['enumeration_answers'] = enumAnswers.entries
              .map((e) => {'order_index': e.key, 'answer_text': e.value})
              .toList()
            ..sort((a, b) =>
                (a['order_index'] as int).compareTo(b['order_index'] as int));
          break;
      }

      answers.add(answer);
    }

    return answers;
  }

  Future<void> _saveAnswers() async {
    if (_submissionId == null) return;
    await ref.read(assessmentProvider.notifier).saveAnswers(
          SaveAnswersParams(
            submissionId: _submissionId!,
            answers: _buildAnswersPayload(),
          ),
        );
  }

  Future<void> _autoSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();
    _autoSaveTimer?.cancel();

    await _saveAnswers();

    if (_submissionId != null) {
      await ref
          .read(assessmentProvider.notifier)
          .submitAssessment(_submissionId!);
    }

    if (mounted) {
      context.showWarningSnackBar('Time is up! Assessment auto-submitted.');
      Navigator.pop(context);
    }
  }

  void _confirmSubmit() {
    AssessmentDialogs.showSubmitConfirmation(
      context,
      onSubmit: _submitAssessment,
    );
  }

  Future<void> _submitAssessment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();
    _autoSaveTimer?.cancel();

    await _saveAnswers();

    if (_submissionId != null) {
      await ref
          .read(assessmentProvider.notifier)
          .submitAssessment(_submissionId!);
    }

    final state = ref.read(assessmentProvider);
    if (mounted) {
      if (state.error != null) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackBar(state.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
        _startCountdown();
        _startAutoSave();
      } else {
        context.showSuccessSnackBar('Assessment submitted successfully!');
        Navigator.pop(context);
      }
    }
  }

  void _handleLeave() {
    _saveAnswers();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null &&
          prev?.error != next.error &&
          !_isSubmitting) {
        context.showErrorSnackBar(next.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    if (!_hasStarted) {
      return _buildLoadingOrErrorState(state);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AssessmentDialogs.showExitWarning(
          context,
          onLeave: _handleLeave,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Assessment',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            AssessmentTimerBadge(remainingSeconds: _remainingSeconds),
          ],
        ),
        body: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == _questions.length) {
                    return AssessmentSubmitSection(
                      remainingSeconds: _remainingSeconds,
                      isSubmitting: _isSubmitting,
                      onSubmit: _confirmSubmit,
                    );
                  }
                  return AssessmentQuestionCard(
                    question: _questions[index],
                    questionNumber: index + 1,
                    selectedChoices: _selectedChoices,
                    textControllers: _textControllers,
                    enumControllers: _enumControllers,
                    onChoicesChanged: (questionId, choices) {
                      setState(() {
                        _selectedChoices[questionId] = choices;
                      });
                    },
                    onTextChanged: (questionId, text) {
                      _textAnswers[questionId] = text;
                    },
                    onEnumChanged: (questionId, index, text) {
                      _enumerationAnswers[questionId] ??= {};
                      _enumerationAnswers[questionId]![index] = text;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _remainingSeconds / (widget.timeLimitMinutes * 60);
    Color progressColor;
    if (_remainingSeconds <= 60) {
      progressColor = const Color(0xFFEA4335);
    } else if (_remainingSeconds <= 300) {
      progressColor = const Color(0xFFFFBD59);
    } else {
      progressColor = const Color(0xFF666666);
    }

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: const Color(0xFFF0F0F0),
      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
      minHeight: 4,
    );
  }

  Widget _buildLoadingOrErrorState(AssessmentState state) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
      ),
      body: Center(
        child: state.error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEBEE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Color(0xFFEA4335),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2B2B2B),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Starting assessment...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}