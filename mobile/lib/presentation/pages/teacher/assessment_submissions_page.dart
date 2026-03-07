import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
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
        context.showErrorSnackBar(next.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: const Text(
          'Submissions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: state.isLoading && state.submissions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : state.submissions.isEmpty
              ? const EmptyAssessmentSubmissionsState()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assessmentProvider.notifier)
                      .loadSubmissions(widget.assessmentId),
                  color: const Color(0xFF2B2B2B),
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
    );
  }
}