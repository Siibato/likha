import 'package:flutter/material.dart';

/// A reusable submission type dropdown for assignment configuration.
/// Displays options: Text Only, File Only, Text and/or File
class SubmissionTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const SubmissionTypeDropdown({
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
        value: value,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Submission Type',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
          prefixIcon: const Icon(
            Icons.upload_file_rounded,
            color: Color(0xFF666666),
            size: 20,
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
          color: Color(0xFF202020),
        ),
        items: const [
          DropdownMenuItem(value: 'text', child: Text('Text Only')),
          DropdownMenuItem(value: 'file', child: Text('File Only')),
          DropdownMenuItem(
            value: 'text_or_file',
            child: Text('Text and/or File'),
          ),
        ],
        dropdownColor: Colors.white,
      ),
    );
  }
}
