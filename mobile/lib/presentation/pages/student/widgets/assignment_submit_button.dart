import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';

class AssignmentSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const AssignmentSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StyledButton(
      text: 'Submit Assignment',
      variant: StyledButtonVariant.primary,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}