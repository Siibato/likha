import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// "Submissions" and "Statistics" action buttons shown on a published assessment.
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onViewSubmissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.foregroundPrimary,
              elevation: 0,
              side: const BorderSide(color: AppColors.borderLight, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
            label: const Text(
              'Submissions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onViewStatistics,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.foregroundPrimary,
              elevation: 0,
              side: const BorderSide(color: AppColors.borderLight, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: const Text(
              'Statistics',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
