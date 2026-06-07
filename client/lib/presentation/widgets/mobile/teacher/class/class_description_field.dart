import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

class ClassDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const ClassDescriptionField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'Description (optional)',
      icon: Icons.description_outlined,
      enabled: enabled,
      maxLines: 4,
    );
  }
}
