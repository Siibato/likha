import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/usecases/grade_essay.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/submission_answer_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/submission_summary_card.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class SubmissionReviewPage extends ConsumerStatefulWidget {
  final String submissionId;

  const SubmissionReviewPage({super.key, required this.submissionId});

  @override
  ConsumerState<SubmissionReviewPage> createState() =>
      _SubmissionReviewPageState();
}

class _SubmissionReviewPageState extends ConsumerState<SubmissionReviewPage> {
  String? _formError;
  final Map<String, TextEditingController> _essayScoreControllers = {};

  @override
  void dispose() {
    for (final c in _essayScoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('SubmissionReviewPage.initState: submissionId=${widget.submissionId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('SubmissionReviewPage.initState: calling loadSubmissionDetail(${widget.submissionId})');
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    });
  }

  Future<void> _gradeEssay(String answerId, double points) async {
    await ref.read(teacherAssessmentProvider.notifier).gradeEssayAnswer(
          GradeEssayParams(answerId: answerId, points: points),
        );

    if (!mounted) return;
    final state = ref.read(teacherAssessmentProvider);
    if (state.error == null) {
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    }
  }

  Future<void> _overrideAnswer(String answerId, bool isCorrect, {double? points}) async {
    await ref.read(teacherAssessmentProvider.notifier).overrideAnswer(
          OverrideAnswerParams(
            answerId: answerId,
            isCorrect: isCorrect,
            points: points,
          ),
        );

    if (!mounted) return;
    final state = ref.read(teacherAssessmentProvider);
    if (state.error == null) {
      // Reload submission detail to reflect updated scores
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);
    final detail = state.currentSubmission;

    ref.listen<TeacherAssessmentState>(teacherAssessmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: Text(
          detail != null ? detail.studentName : 'Submission Review',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: state.isLoading && detail == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : detail == null
              ? const Center(
                  child: Text(
                    'Submission not found',
                    style: TextStyle(color: AppColors.foregroundTertiary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormMessage(
                        message: _formError,
                        severity: MessageSeverity.error,
                      ),
                      if (_formError != null) const SizedBox(height: 12),
                      SubmissionSummaryCard(detail: detail),
                      const SizedBox(height: 16),
                      const Text(
                        'Answers',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foregroundDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          debugPrint('SubmissionReviewPage: detail.answers.length=${detail.answers.length} for submissionId=${widget.submissionId}');
                          return const SizedBox.shrink();
                        },
                      ),
                      if (detail.answers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Answers not available offline.\nOpen this submission while online to cache them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.foregroundTertiary),
                            ),
                          ),
                        )
                      else
                        ...detail.answers.asMap().entries.map((entry) {
                          final answer = entry.value;
                          final ctrl = _essayScoreControllers.putIfAbsent(
                            answer.id,
                            () => TextEditingController(
                              text: answer.isPendingEssayGrade
                                  ? ''
                                  : answer.pointsAwarded.toStringAsFixed(
                                      answer.pointsAwarded % 1 == 0 ? 0 : 1,
                                    ),
                            ),
                          );
                          return SubmissionAnswerCard(
                            answer: answer,
                            index: entry.key,
                            essayScoreController: ctrl,
                            onGradeEssay: _gradeEssay,
                            onOverride: _overrideAnswer,
                            onValidationError: (msg) =>
                                setState(() => _formError = msg),
                          );
                        }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

}
