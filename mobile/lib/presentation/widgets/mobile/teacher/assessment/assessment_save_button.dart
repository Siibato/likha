import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

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
    return StyledButton(
      text: label,
      isLoading: isSaving,
      onPressed: (isSaving || isDisabled) ? () {} : onSave ?? () {},
      variant: StyledButtonVariant.primary,
      fullWidth: true,
    );
  }
}
