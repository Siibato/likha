import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/controllers/teacher/assessment/submission_review_controller.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/submission_answer_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/submission_summary_card.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';

class SubmissionReviewPage extends ConsumerStatefulWidget {
  final String submissionId;

  const SubmissionReviewPage({super.key, required this.submissionId});

  @override
  ConsumerState<SubmissionReviewPage> createState() =>
      _SubmissionReviewPageState();
}

class _SubmissionReviewPageState
    extends ConsumerState<SubmissionReviewPage> {
  late final SubmissionReviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SubmissionReviewController(
      submissionId: widget.submissionId,
      notifier: ref.read(teacherAssessmentProvider.notifier),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);
    final detail = state.currentSubmission?.id == widget.submissionId
        ? state.currentSubmission
        : null;

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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return state.isLoading && detail == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.foregroundPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : detail == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.error != null) ...[
                              FormMessage(
                                message: state.error,
                                severity: MessageSeverity.error,
                              ),
                              const SizedBox(height: 12),
                            ] else
                              const Text(
                                'Submission not found',
                                style: TextStyle(color: AppColors.foregroundTertiary),
                              ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FormMessage(
                            message: _controller.formError,
                            severity: MessageSeverity.error,
                          ),
                          if (_controller.formError != null)
                            const SizedBox(height: 12),
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
                              final ctrl = _controller.getOrCreateEssayController(answer);
                              return SubmissionAnswerCard(
                                answer: answer,
                                index: entry.key,
                                essayScoreController: ctrl,
                                onGradeEssay: _controller.gradeEssay,
                                onOverride: _controller.overrideAnswer,
                                onValidationError: (msg) =>
                                    _controller.setFormError(msg),
                              );
                            }),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
        },
      ),
    );
  }
}
