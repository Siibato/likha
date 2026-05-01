import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment/submission_review_desktop.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/submission_data_table.dart';
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

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
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
        body: state.isLoading && submissions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(
                    color: AppColors.foregroundPrimary,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : SubmissionDataTable(
                columns: [
                  const SubmissionColumn(
                    key: 'studentName',
                    label: 'Student Name',
                    sortable: true,
                  ),
                  const SubmissionColumn(
                    key: 'studentUsername',
                    label: 'Username',
                  ),
                  SubmissionColumn(
                    key: 'isSubmitted',
                    label: 'Status',
                    cellBuilder: (value) => _buildStatusBadge(value == true),
                  ),
                  const SubmissionColumn(
                    key: 'autoScore',
                    label: 'Auto Score',
                    numeric: true,
                  ),
                  const SubmissionColumn(
                    key: 'finalScore',
                    label: 'Final Score',
                    numeric: true,
                  ),
                  const SubmissionColumn(
                    key: 'submittedAt',
                    label: 'Submitted At',
                  ),
                ],
                rows: submissions
                    .map((s) => {
                          'id': s.id,
                          'studentName': s.studentName,
                          'studentUsername': s.studentUsername,
                          'isSubmitted': s.isSubmitted,
                          'autoScore':
                              '${s.autoScore}/${s.totalPoints}',
                          'finalScore':
                              '${s.finalScore}/${s.totalPoints}',
                          'submittedAt': _formatDate(s.submittedAt),
                        })
                    .toList(),
                onTap: (row) {
                  final submission = submissions.firstWhere(
                    (s) => s.id == row['id'],
                  );
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
}
