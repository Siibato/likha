import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/base_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/status_badge.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/empty_state.dart';

class AssessmentDataTable extends StatelessWidget {
  final List<Assessment> assessments;
  final ValueChanged<Assessment> onTap;
  final int rowsPerPage;

  const AssessmentDataTable({
    super.key,
    required this.assessments,
    required this.onTap,
    this.rowsPerPage = 20,
  });

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BaseDataTable<Assessment>(
      items: assessments,
      rowsPerPage: rowsPerPage,
      emptyState: const EmptyState.assessments(),
      columnFlexes: const [3, 1, 1, 1, 1, 1],
      columns: [
        DataColumn(
          label: const Text('Title', style: dataTableHeaderStyle),
          onSort: (_, __) {}, // Sorting handled by BaseDataTable
        ),
        const DataColumn(
          label: Text('Questions', style: dataTableHeaderStyle),
          numeric: true,
        ),
        const DataColumn(
          label: Text('Status', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Open', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Close', style: dataTableHeaderStyle),
        ),
        const DataColumn(
          label: Text('Submissions', style: dataTableHeaderStyle),
          numeric: true,
        ),
      ],
      rowBuilder: (context, assessment, index) {
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  assessment.title,
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
                  '${assessment.questionCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: StatusBadge.published(isPublished: assessment.isPublished),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _formatDate(assessment.openAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _formatDate(assessment.closeAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${assessment.submissionCount}',
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
