import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

class AssignmentPointsField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const AssignmentPointsField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      controller: controller,
      label: 'Total Points',
      icon: Icons.star_outline_rounded,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Total points is required';
        final points = int.tryParse(value.trim());
        if (points == null) return 'Must be a valid number';
        if (points < 1 || points > 1000) return 'Points must be between 1 and 1000';
        return null;
      },
    );
  }
}
