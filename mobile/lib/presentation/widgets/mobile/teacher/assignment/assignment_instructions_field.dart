import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';

class AssignmentInstructionsField extends StatelessWidget {
  final FleatherController controller;
  final bool enabled;

  const AssignmentInstructionsField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return RichTextField(
      controller: controller,
      label: 'Instructions',
      icon: Icons.description_outlined,
      enabled: enabled,
      minHeight: 120,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Instructions are required';
        return null;
      },
    );
  }
}
