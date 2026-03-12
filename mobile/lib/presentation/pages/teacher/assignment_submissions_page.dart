import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/teacher/grade_submission_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_submissions_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/submission_card.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class AssignmentSubmissionsPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final int totalPoints;

  const AssignmentSubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.totalPoints,
  });

  @override
  ConsumerState<AssignmentSubmissionsPage> createState() =>
      _AssignmentSubmissionsPageState();
}

class _AssignmentSubmissionsPageState
    extends ConsumerState<AssignmentSubmissionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissions(widget.assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submissions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              widget.assignmentTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ),
      ),
      body: state.isLoading && state.submissions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : state.submissions.isEmpty
              ? const EmptySubmissionsState()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(assignmentProvider.notifier)
                      .loadSubmissions(widget.assignmentId),
                  color: AppColors.foregroundPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: state.submissions.length,
                    itemBuilder: (context, index) {
                      final submission = state.submissions[index];

                      return SubmissionCard(
                        studentName: submission.studentName,
                        status: submission.status,
                        isLate: submission.isLate,
                        score: submission.score,
                        totalPoints: widget.totalPoints,
                        submittedAt: submission.submittedAt,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GradeSubmissionPage(
                              submissionId: submission.id,
                              totalPoints: widget.totalPoints,
                            ),
                          ),
                        ).then((_) => ref
                            .read(assignmentProvider.notifier)
                            .loadSubmissions(widget.assignmentId)),
                      );
                    },
                  ),
                ),
    );
  }
}