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
        color: const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.deprecatedWarningYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay_rounded, color: AppColors.deprecatedWarningYellow, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Returned for Revision',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: const TextStyle(
              color: Color(0xFF2B2B2B),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}