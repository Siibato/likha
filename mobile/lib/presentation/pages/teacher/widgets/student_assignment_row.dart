import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/presentation/pages/teacher/assignment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/grade_submission_page.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card_sm.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/chevron_trailing.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/status_badge.dart';

class StudentAssignmentRow extends StatelessWidget {
  final Assignment assignment;
  final StudentAssignmentStatus? status;
  final VoidCallback? onTap;

  const StudentAssignmentRow({
    super.key,
    required this.assignment,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCardSm(
      onTap: status != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeSubmissionPage(
                    submissionId: status!.submissionId,
                    totalPoints: assignment.totalPoints,
                  ),
                ),
              )
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignmentDetailPage(
                    assignmentId: assignment.id,
                  ),
                ),
              ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.task_alt_outlined,
              size: 18,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(width: 12),
          // Title and due date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${_formatDate(assignment.dueAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status badge or score
          _buildStatusWidget(),
          const SizedBox(width: 8),
          const ChevronTrailing(),
        ],
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (status == null) {
      return const StatusBadge(
        label: 'Not Submitted',
        color: AppColors.foregroundTertiary,
        variant: BadgeVariant.filled,
      );
    }

    switch (status!.status.toLowerCase()) {
      case 'draft':
        return const StatusBadge(
          label: 'Draft',
          color: AppColors.foregroundTertiary,
          variant: BadgeVariant.filled,
        );
      case 'submitted':
        return const StatusBadge(
          label: 'Submitted',
          color: AppColors.foregroundSecondary,
          variant: BadgeVariant.filled,
        );
      case 'graded':
        final score = status!.score ?? 0;
        return Text(
          '$score / ${assignment.totalPoints} pts',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.semanticSuccess,
          ),
        );
      case 'returned':
        return const StatusBadge(
          label: 'Returned',
          color: AppColors.deprecatedDraftOrange,
          variant: BadgeVariant.filled,
        );
      default:
        return StatusBadge(
          label: status!.status,
          color: AppColors.foregroundTertiary,
          variant: BadgeVariant.filled,
        );
    }
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month/$day/${dt.year}';
  }
}
