import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Summary card showing submission and graded counts.
class AssignmentSubmissionsSummary extends StatelessWidget {
  final int submissionCount;
  final int gradedCount;

  const AssignmentSubmissionsSummary({
    super.key,
    required this.submissionCount,
    required this.gradedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submissions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(label: 'Submitted', value: '$submissionCount'),
          const SizedBox(height: 12),
          _StatRow(label: 'Graded', value: '$gradedCount'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
      ],
    );
  }
}
