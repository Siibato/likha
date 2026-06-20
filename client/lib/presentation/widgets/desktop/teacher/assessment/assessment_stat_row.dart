import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssessmentStatRow extends StatelessWidget {
  final String label;
  final String value;

  const AssessmentStatRow({
    super.key,
    required this.label,
    required this.value,
  });

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
