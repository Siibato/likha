import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

class AssessmentStatusBadge extends StatelessWidget {
  final Assessment assessment;

  const AssessmentStatusBadge({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final isPublished = assessment.isPublished;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.semanticSuccessBackground
            : AppColors.accentAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? AppColors.semanticSuccess
              : AppColors.accentAmber,
        ),
      ),
    );
  }
}
