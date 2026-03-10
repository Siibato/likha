import 'package:flutter/material.dart';

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
        highlightColor: const Color(0xFFFAFAFA),
        splashColor: const Color(0xFFFAFAFA),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Question Type',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2B2B2B),
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
          color: Color(0xFF2B2B2B),
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
        ],
        dropdownColor: Colors.white,
      ),
    );
  }
}
