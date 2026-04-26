import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class EmptyStudentState extends StatelessWidget {
  const EmptyStudentState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No students enrolled yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}