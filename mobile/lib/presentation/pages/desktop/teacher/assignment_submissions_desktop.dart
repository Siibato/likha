import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade_submission_desktop.dart';
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
        body: _buildBody(state.isLoading, submissions),
      ),
    );
  }

  Widget _buildBody(bool isLoading, List<SubmissionListItem> submissions) {
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.foregroundTertiary,
            ),
            SizedBox(height: 12),
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
          dataRowMaxHeight: 56,
          horizontalMargin: 20,
          columnSpacing: 24,
          columns: const [
            DataColumn(
              label: Text('Student Name', style: _headerStyle),
            ),
            DataColumn(
              label: Text('Username', style: _headerStyle),
            ),
            DataColumn(
              label: Text('Status', style: _headerStyle),
            ),
            DataColumn(
              label: Text('Late', style: _headerStyle),
            ),
            DataColumn(
              label: Text('Score', style: _headerStyle),
              numeric: true,
            ),
            DataColumn(
              label: Text('Submitted At', style: _headerStyle),
            ),
          ],
          rows: submissions.map((submission) {
            return DataRow(
              onSelectChanged: (_) {
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
              cells: [
                DataCell(Text(
                  submission.studentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundDark,
                  ),
                )),
                DataCell(Text(
                  submission.studentUsername,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                )),
                DataCell(_buildStatusBadge(submission.status)),
                DataCell(
                  submission.isLate
                      ? _buildLateBadge()
                      : const Text(
                          '--',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                ),
                DataCell(Text(
                  submission.score != null
                      ? '${submission.score}/${widget.totalPoints}'
                      : '--',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                )),
                DataCell(Text(
                  _formatDate(submission.submittedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                )),
              ],
            );
          }).toList(),
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
        badgeColor = const Color(0xFF28A745);
        break;
      case 'returned':
        badgeColor = const Color(0xFFFFA726);
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

  Widget _buildLateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.semanticError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Late',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.semanticError,
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
