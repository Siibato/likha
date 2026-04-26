import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssignmentSubmissionsCard extends StatelessWidget {
  final int submissionCount;
  final int gradedCount;
  final VoidCallback onTap;

  const AssignmentSubmissionsCard({
    super.key,
    required this.submissionCount,
    required this.gradedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppColors.foregroundSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submissions',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.foregroundDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$submissionCount submitted • $gradedCount graded',
                    style: const TextStyle(
                      color: AppColors.foregroundTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.borderLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}