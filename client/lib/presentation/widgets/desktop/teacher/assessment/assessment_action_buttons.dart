import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssessmentActionButtons extends StatelessWidget {
  final VoidCallback onViewSubmissions;
  final VoidCallback onViewStatistics;

  const AssessmentActionButtons({
    super.key,
    required this.onViewSubmissions,
    required this.onViewStatistics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onViewSubmissions,
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: const Text('View Submissions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foregroundDark,
              side: const BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onViewStatistics,
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: const Text('View Statistics'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foregroundDark,
              side: const BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
