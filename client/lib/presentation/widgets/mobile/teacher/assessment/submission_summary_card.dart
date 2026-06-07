import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Summary card at the top of SubmissionReviewPage showing student info,
/// auto/final score, and submission timestamp.
class SubmissionSummaryCard extends StatelessWidget {
  final SubmissionDetail detail;

  const SubmissionSummaryCard({super.key, required this.detail});

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundTertiary,
                child: Text(
                  detail.studentName.isNotEmpty
                      ? detail.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.foregroundPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.studentName, style: AppTextStyles.cardTitleMd),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: detail.isSubmitted ? 'Submitted' : 'In Progress',
                      color: detail.isSubmitted
                          ? AppColors.semanticSuccess
                          : AppColors.foregroundSecondary,
                      variant: BadgeVariant.filled,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreColumn('Auto Score', detail.autoScore,
                  AppColors.foregroundSecondary),
              _scoreColumn('Final Score', detail.finalScore,
                  AppColors.foregroundPrimary),
            ],
          ),
          if (detail.submittedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Submitted: ${_formatDateTime(detail.submittedAt!)}',
              style: AppTextStyles.cardSubtitleMd,
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, double score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style:
              const TextStyle(fontSize: 12, color: AppColors.foregroundTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          score % 1 == 0
              ? score.toInt().toString()
              : score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
