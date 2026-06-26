import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/controllers/teacher/assessment/submission_review_controller.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/assessment/submission_review_notifier.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/submission_review_answer_card.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/submission_review_grading_panel.dart';
import 'package:likha/presentation/widgets/shared/dialogs/override_grade_dialog.dart';
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
      notifier: ref.read(submissionReviewProvider.notifier),
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

  void _confirmOverride(SubmissionAnswer answer) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: OverrideGradeDialog(
          answer: answer,
          onConfirm: (isCorrect, points) {
            _controller.overrideAnswer(answer.id, isCorrect, points: points);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(submissionReviewProvider);
    final detail = providerState.currentSubmission?.id == widget.submissionId
        ? providerState.currentSubmission
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return DesktopPageScaffold(
            title: detail != null ? detail.studentName : 'Submission Review',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.foregroundPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            scrollable: false,
            body: providerState.isLoading && detail == null
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
                              if (providerState.error != null) ...[
                                FormMessage(
                                  message: providerState.error,
                                  severity: MessageSeverity.error,
                                ),
                                const SizedBox(height: 12),
                              ] else
                                const Text(
                                  'Submission not found',
                                  style:
                                      TextStyle(color: AppColors.foregroundTertiary),
                                ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormMessage(
                            message: _controller.formError,
                            severity: MessageSeverity.error,
                          ),
                          if (_controller.formError != null)
                            const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    padding:
                                        const EdgeInsets.only(right: 24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Answers',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.foregroundDark,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ...detail.answers
                                            .asMap()
                                            .entries
                                            .map((entry) =>
                                                SubmissionReviewAnswerCard(
                                                  answer: entry.value,
                                                  index: entry.key,
                                                  onOverride: () =>
                                                      _confirmOverride(
                                                          entry.value),
                                                )),
                                        const SizedBox(height: 32),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: SingleChildScrollView(
                                    child: SubmissionReviewGradingPanel(
                                      detail: detail,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          );
        },
      ),
    );
  }
}
