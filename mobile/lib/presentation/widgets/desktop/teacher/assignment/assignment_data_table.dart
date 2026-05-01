import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/base_data_table.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/status_badge.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';

class AssignmentDataTable extends StatelessWidget {
  final List<Assignment> assignments;
  final ValueChanged<Assignment> onTap;
  final int rowsPerPage;

  const AssignmentDataTable({
    super.key,
    required this.assignments,
    required this.onTap,
    this.rowsPerPage = 20,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatSubmissionType(bool allowsText, bool allowsFile) {
    if (allowsText && allowsFile) {
      return 'Text / File';
    } else if (allowsText) {
      return 'Text Only';
    } else if (allowsFile) {
      return 'File Only';
    } else {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDataTable<Assignment>(
      items: assignments,
      rowsPerPage: rowsPerPage,
      emptyState: const EmptyState.assignments(),
      columnFlexes: const [3, 1, 1, 1, 1, 1, 1],
      columns: [
        DataColumn(
          label: const Text('Title', style: dataTableHeaderStyle),
          onSort: (_, __) {}, // Sorting handled by BaseDataTable
        ),
        const DataColumn(
          label: Text('Points', style: dataTableHeaderStyle),
          numeric: true,
        ),
        const DataColumn(
          label: Text('Type', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Status', style: dataTableHeaderStyle),
        ),
        DataColumn(
          label: const Text('Due Date', style: dataTableHeaderStyle),
          onSort: (_, __) {}, // Sorting handled by BaseDataTable
        ),
        const DataColumn(
          label: Text('Submissions', style: dataTableHeaderStyle),
          numeric: true,
        ),
        const DataColumn(
          label: Text('Graded', style: dataTableHeaderStyle),
          numeric: true,
        ),
      ],
      rowBuilder: (context, assignment, index) {
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  assignment.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foregroundDark,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${assignment.totalPoints}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _formatSubmissionType(assignment.allowsTextSubmission, assignment.allowsFileSubmission),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: StatusBadge.published(isPublished: assignment.isPublished),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _formatDate(assignment.dueAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${assignment.submissionCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${assignment.gradedCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onTap: onTap,
    );
  }
}
