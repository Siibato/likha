import 'package:flutter/material.dart';

import 'package:likha/core/theme/app_colors.dart';

/// Desktop content section for material description.
class MaterialContentSection extends StatelessWidget {
  final String heading;
  final String text;

  const MaterialContentSection({
    super.key,
    required this.heading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
