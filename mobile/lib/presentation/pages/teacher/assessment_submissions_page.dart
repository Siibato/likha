import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/submission_review_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/assessment_submission_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assessment_submissions_state.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class AssessmentSubmissionsPage extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentSubmissionsPage({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentSubmissionsPage> createState() =>
      _AssessmentSubmissionsPageState();
}

class _AssessmentSubmissionsPageState
    extends ConsumerState<AssessmentSubmissionsPage> {
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentProvider.notifier)
          .loadSubmissions(widget.assessmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: const Text(
          'Submissions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_formError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FormMessage(
                message: _formError,
                severity: MessageSeverity.error,
              ),
            ),
          Expanded(
            child: state.isLoading && state.submissions.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : state.submissions.isEmpty
                    ? const EmptyAssessmentSubmissionsState()
                    : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assessmentProvider.notifier)
                      .loadSubmissions(widget.assessmentId),
                  color: AppColors.foregroundPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: state.submissions.length,
                    itemBuilder: (context, index) {
                      final submission = state.submissions[index];
                      return AssessmentSubmissionCard(
                        studentName: submission.studentName,
                        studentUsername: submission.studentUsername,
                        isSubmitted: submission.isSubmitted,
                        submittedAt: submission.submittedAt,
                        startedAt: submission.startedAt,
                        finalScore: submission.finalScore,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmissionReviewPage(
                              submissionId: submission.id,
                            ),
                          ),
                        ).then((_) => ref
                            .read(assessmentProvider.notifier)
                            .loadSubmissions(widget.assessmentId)),
                      );
                    },
                  ),
                ),
            ),
        ],
      ),
    );
  }
}