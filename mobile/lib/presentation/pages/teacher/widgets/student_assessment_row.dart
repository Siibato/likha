import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/pages/teacher/assessment/assessment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/assessment/submission_review_page.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card_sm.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/chevron_trailing.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/status_badge.dart';

class StudentAssessmentRow extends StatelessWidget {
  final Assessment assessment;
  final SubmissionSummary? submission;
  final VoidCallback? onTap;

  const StudentAssessmentRow({
    super.key,
    required this.assessment,
    this.submission,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCardSm(
      onTap: submission != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmissionReviewPage(
                    submissionId: submission!.id,
                  ),
                ),
              )
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssessmentDetailPage(
                    assessmentId: assessment.id,
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
              Icons.assignment_outlined,
              size: 18,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(width: 12),
          // Title and close date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.title,
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
                  'Closes: ${_formatDate(assessment.closeAt)}',
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
    if (submission == null) {
      return const StatusBadge(
        label: 'Not Attempted',
        color: AppColors.foregroundTertiary,
        variant: BadgeVariant.filled,
      );
    }

    if (!submission!.isSubmitted) {
      return const StatusBadge(
        label: 'In Progress',
        color: AppColors.deprecatedDraftOrange,
        variant: BadgeVariant.filled,
      );
    }

    if (!assessment.resultsReleased) {
      return const StatusBadge(
        label: 'Submitted',
        color: AppColors.foregroundSecondary,
        variant: BadgeVariant.filled,
      );
    }

    // Results released
    final score = submission!.finalScore % 1 == 0
        ? submission!.finalScore.toInt()
        : submission!.finalScore.toStringAsFixed(1);
    return Text(
      '$score / ${assessment.totalPoints} pts',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.semanticSuccess,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month/$day/${dt.year}';
  }
}
