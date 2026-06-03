import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';

/// Displays teacher feedback text for a graded assignment submission.
class AssignmentFeedbackCard extends StatelessWidget {
  final String feedback;

  const AssignmentFeedbackCard({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teacher Feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.accentCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}
