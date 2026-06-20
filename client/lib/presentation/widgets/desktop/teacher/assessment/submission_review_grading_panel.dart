import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';

/// Right-side grading panel for the desktop submission review page.
class SubmissionReviewGradingPanel extends StatelessWidget {
  final SubmissionDetail detail;
  final void Function(SubmissionAnswer answer) onOverride;

  const SubmissionReviewGradingPanel({
    super.key,
    required this.detail,
    required this.onOverride,
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

          // Score summary
          _ScoreRow(label: 'Auto Score', value: detail.autoScore, color: AppColors.foregroundSecondary),
          const SizedBox(height: 12),
          _ScoreRow(label: 'Final Score', value: detail.finalScore, color: AppColors.foregroundPrimary),
          const SizedBox(height: 12),
          _ScoreRow(label: 'Total Points', value: detail.totalPoints.toDouble(), color: AppColors.foregroundTertiary),

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
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),

          // Per-question override section
          const Text(
            'Grade Overrides',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...detail.answers.asMap().entries.map((entry) {
            final answer = entry.value;
            final index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}. ${answer.questionText}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: TextButton.icon(
                              onPressed: () => onOverride(answer),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Override Grade',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.foregroundPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        Text(
          display,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
