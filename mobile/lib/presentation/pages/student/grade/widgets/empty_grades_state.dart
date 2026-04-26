import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class EmptyGradesState extends StatelessWidget {
  const EmptyGradesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.foregroundLight,
          ),
          SizedBox(height: 16),
          Text(
            'No classes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.accentCharcoal,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Check back later',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
