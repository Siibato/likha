import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';

class AssignmentInstructionsField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const AssignmentInstructionsField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'Instructions',
      icon: Icons.description_outlined,
      enabled: enabled,
      maxLines: 5,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Instructions are required';
        return null;
      },
    );
  }
}
