import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

/// Full-width outlined button that lets the student start a new submission attempt.
class AssignmentNewAttemptButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AssignmentNewAttemptButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return StyledButton(
      text: 'Create New Attempt',
      variant: StyledButtonVariant.outlined,
      isLoading: false,
      onPressed: onPressed,
    );
  }
}
