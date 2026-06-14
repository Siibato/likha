import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Status badge showing whether an assignment is published or draft.
class AssignmentStatusBadge extends StatelessWidget {
  final bool isPublished;

  const AssignmentStatusBadge({super.key, required this.isPublished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.semanticSuccessAlt.withValues(alpha: 0.12)
            : AppColors.foregroundTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? AppColors.semanticSuccessAlt
              : AppColors.foregroundTertiary,
        ),
      ),
    );
  }
}
