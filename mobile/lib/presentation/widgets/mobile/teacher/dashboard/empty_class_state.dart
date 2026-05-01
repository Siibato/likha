import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class EmptyClassState extends StatelessWidget {
  const EmptyClassState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.class_outlined,
              size: 64,
              color: AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No classes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to create your first class',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}