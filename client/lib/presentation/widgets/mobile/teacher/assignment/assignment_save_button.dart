import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssignmentSaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const AssignmentSaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentCharcoal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.borderLight,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Create Assignment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
    );
  }
}
