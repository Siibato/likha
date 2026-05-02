import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';
import 'package:likha/presentation/pages/teacher/assessment/submission_review_page.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_submission_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/empty_assessment_submissions_state.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

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
          .read(teacherAssessmentProvider.notifier)
          .loadSubmissions(widget.assessmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);

    ref.listen<TeacherAssessmentState>(teacherAssessmentProvider, (prev, next) {
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
            child: ContentStateBuilder(
              isLoading: state.isLoading && state.submissions.isEmpty,
              error: state.error,
              isEmpty: state.submissions.isEmpty,
              onRetry: () => ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadSubmissions(widget.assessmentId),
              onRefresh: () => ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadSubmissions(widget.assessmentId),
              emptyState: const EmptyAssessmentSubmissionsState(),
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
                        .read(teacherAssessmentProvider.notifier)
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