import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Full-width outlined button that lets the student start a new submission attempt.
class AssignmentNewAttemptButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AssignmentNewAttemptButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
          foregroundColor: AppColors.accentCharcoal,
        ),
        child: const Text(
          'Create New Attempt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
