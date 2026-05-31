import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade/grade_submission_desktop.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/submission_data_table.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';

class AssignmentSubmissionsDesktop extends ConsumerStatefulWidget {
  final String assignmentId;
  final String title;
  final int totalPoints;

  const AssignmentSubmissionsDesktop({
    super.key,
    required this.assignmentId,
    required this.title,
    required this.totalPoints,
  });

  @override
  ConsumerState<AssignmentSubmissionsDesktop> createState() =>
      _AssignmentSubmissionsDesktopState();
}

class _AssignmentSubmissionsDesktopState
    extends ConsumerState<AssignmentSubmissionsDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentProvider.notifier)
          .loadSubmissions(widget.assignmentId);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final submissions = state.submissions;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Submissions',
        subtitle: widget.title,
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
                    key: 'status',
                    label: 'Status',
                    cellBuilder: (value) =>
                        _buildStatusBadge(value as String? ?? 'pending'),
                  ),
                                    const SubmissionColumn(
                    key: 'score',
                    label: 'Score',
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
                          'status': s.status,
                          // isLate field removed - no longer needed
                          'score': s.score != null
                              ? '${s.score}/${widget.totalPoints}'
                              : '--',
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
                      builder: (_) => GradeSubmissionDesktop(
                        submissionId: submission.id,
                        totalPoints: widget.totalPoints,
                      ),
                    ),
                  ).then((_) {
                    ref
                        .read(assignmentProvider.notifier)
                        .loadSubmissions(widget.assignmentId);
                  });
                },
              ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'submitted':
        badgeColor = AppColors.foregroundSecondary;
        break;
      case 'graded':
        badgeColor = AppColors.semanticSuccessAlt;
        break;
      case 'returned':
        badgeColor = AppColors.accentAmber;
        break;
      default:
        badgeColor = AppColors.foregroundTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}