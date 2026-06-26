import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';

/// Right-side grading panel for the desktop submission review page.
class SubmissionReviewGradingPanel extends StatelessWidget {
  final SubmissionDetail detail;

  const SubmissionReviewGradingPanel({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundTertiary,
                radius: 20,
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
                    Text(
                      detail.studentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundDark,
                      ),
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),

          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              Text(
                () {
                  final earned = detail.finalScore % 1 == 0
                      ? detail.finalScore.toInt().toString()
                      : detail.finalScore.toStringAsFixed(1);
                  final total = detail.answers.fold<int>(
                      0, (sum, a) => sum + a.points);
                  return '$earned / $total';
                }(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),

          if (detail.submittedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Submitted: ${Formatters.formatDateTime(detail.submittedAt!)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

