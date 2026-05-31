import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

class AssignmentTitleField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AssignmentTitleField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'Title',
      icon: Icons.title_rounded,
      enabled: enabled,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Title is required';
        if (value.trim().length > 200) return 'Title must be 200 characters or less';
        return null;
      },
    );
  }
}
