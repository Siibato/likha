import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_save_button.dart';

/// Bottom action bar for the mobile assessment creation page.
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
            disabledForegroundColor: AppColors.foregroundLight,
          ),
          child: const Text(
            'Save Draft',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AssessmentSaveButton(
            isSaving: isSaving,
            isDisabled: isDisabled,
            onSave: onSave,
          ),
        ),
      ],
    );
  }
}
