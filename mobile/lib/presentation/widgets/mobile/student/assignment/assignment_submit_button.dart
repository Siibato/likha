import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

class AssignmentSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String? text;

  const AssignmentSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return StyledButton(
      text: text ?? 'Submit Assignment',
      variant: StyledButtonVariant.primary,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}