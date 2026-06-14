import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// App-bar action buttons for the desktop assessment creation page.
class AssessmentCreateActions extends StatelessWidget {
  final bool isSaving;
  final bool isDisabled;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;

  const AssessmentCreateActions({
    super.key,
    required this.isSaving,
    required this.isDisabled,
    required this.onSaveDraft,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: isSaving ? null : onSaveDraft,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentCharcoal,
            side: const BorderSide(color: AppColors.borderLight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save Draft',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isSaving || isDisabled ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentCharcoal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.borderLight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                  'Save Assessment',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
        ),
      ],
    );
  }
}
