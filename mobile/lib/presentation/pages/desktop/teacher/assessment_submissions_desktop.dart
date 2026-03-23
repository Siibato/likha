import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/submission_review_desktop.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class AssessmentSubmissionsDesktop extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentSubmissionsDesktop({
    super.key,
    required this.assessmentId,
  });

  @override
  ConsumerState<AssessmentSubmissionsDesktop> createState() =>
      _AssessmentSubmissionsDesktopState();
}

class _AssessmentSubmissionsDesktopState
    extends ConsumerState<AssessmentSubmissionsDesktop> {
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
    final submissions = state.submissions;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Submissions',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.foregroundDark,
          ),
        ),
        body: _buildBody(state.isLoading, submissions),
      ),
    );
  }

  Widget _buildBody(bool isLoading, List submissions) {
    if (isLoading && submissions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(
            color: AppColors.foregroundPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.foregroundTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No submissions yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor:
              WidgetStateProperty.all(AppColors.backgroundTertiary),
          columns: const [
            DataColumn(label: Text('Student Name')),
            DataColumn(label: Text('Username')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Auto Score')),
            DataColumn(label: Text('Final Score')),
            DataColumn(label: Text('Submitted At')),
          ],
          rows: submissions.map((submission) {
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmissionReviewDesktop(
                      submissionId: submission.id,
                    ),
                  ),
                ).then((_) {
                  ref
                      .read(teacherAssessmentProvider.notifier)
                      .loadSubmissions(widget.assessmentId);
                });
              },
              cells: [
                DataCell(Text(
                  submission.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundPrimary,
                  ),
                )),
                DataCell(Text(
                  submission.studentUsername,
                  style: const TextStyle(
                    color: AppColors.foregroundSecondary,
                  ),
                )),
                DataCell(_buildStatusBadge(submission.isSubmitted)),
                DataCell(Text(
                  '${submission.autoScore}/${submission.totalPoints}',
                  style: const TextStyle(
                    color: AppColors.foregroundSecondary,
                  ),
                )),
                DataCell(Text(
                  '${submission.finalScore}/${submission.totalPoints}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundPrimary,
                  ),
                )),
                DataCell(Text(
                  _formatDate(submission.submittedAt),
                  style: const TextStyle(
                    color: AppColors.foregroundSecondary,
                    fontSize: 13,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isSubmitted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSubmitted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSubmitted ? 'Submitted' : 'In Progress',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSubmitted ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
