import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Full-width save CTA for the create/edit assessment page.
///
/// Shows a spinner when [isSaving] is true. Disabled when [isSaving]
/// or [isDisabled] is true.
class AssessmentSaveButton extends StatelessWidget {
  final bool isSaving;
  final bool isDisabled;
  final VoidCallback? onSave;
  final String label;

  const AssessmentSaveButton({
    super.key,
    required this.isSaving,
    this.isDisabled = false,
    required this.onSave,
    this.label = 'Save Assessment',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (isSaving || isDisabled) ? null : onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentCharcoal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.borderLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
    );
  }
}
