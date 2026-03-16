import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssessmentField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int? maxLines;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const AssessmentField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    required this.icon,
    this.validator,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiLine = maxLines != null && maxLines! > 1;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      textAlignVertical: isMultiLine ? TextAlignVertical.top : TextAlignVertical.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2B2B2B),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        prefixIcon: isMultiLine
            ? Align(
                widthFactor: 1.0,
                heightFactor: 1.0,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Icon(
                    icon,
                    color: const Color(0xFF666666),
                    size: 20,
                  ),
                ),
              )
            : Icon(
                icon,
                color: const Color(0xFF666666),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF5350),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF5350),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}