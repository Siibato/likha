import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';

class ClassTitleField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const ClassTitleField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'Class Title',
      icon: Icons.class_outlined,
      enabled: enabled,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Class title is required';
        return null;
      },
    );
  }
}
