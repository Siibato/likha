import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A reusable question type dropdown that extends StyledDropdown styling
/// with specific field styling for question type selection.
class QuestionTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const QuestionTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: AppColors.backgroundSecondary,
        splashColor: AppColors.backgroundSecondary,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Question Type',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.foregroundTertiary,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.accentCharcoal,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.foregroundPrimary,
        ),
        items: const [
          DropdownMenuItem(
            value: 'multiple_choice',
            child: Text('Multiple Choice'),
          ),
          DropdownMenuItem(
            value: 'identification',
            child: Text('Identification'),
          ),
          DropdownMenuItem(
            value: 'enumeration',
            child: Text('Enumeration'),
          ),
          DropdownMenuItem(
            value: 'essay',
            child: Text('Essay'),
          ),
        ],
        dropdownColor: Colors.white,
      ),
    );
  }
}
