import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssignmentReturnedBanner extends StatelessWidget {
  final String feedback;

  const AssignmentReturnedBanner({
    super.key,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentAmberSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentAmberBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.replay_rounded, color: AppColors.accentAmberBorder, size: 22),
              SizedBox(width: 10),
              Text(
                'Returned for Revision',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: const TextStyle(
              color: AppColors.foregroundPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}