import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';

class CreateClassButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const CreateClassButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StyledButton(
      text: 'Create Class',
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}
