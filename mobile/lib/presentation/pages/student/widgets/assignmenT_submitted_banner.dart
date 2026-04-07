import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';

class AssignmentSubmittedBanner extends StatelessWidget {
  const AssignmentSubmittedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPanel(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.foregroundSecondary,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Assignment submitted. Waiting for teacher to grade.',
              style: TextStyle(
                color: Color(0xFF2B2B2B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}