import 'package:flutter/material.dart';

/// A styled text input field that matches the app's design system.
///
/// Provides a 2-layer container appearance with extensive configuration options
/// including icons, multiline support, and various input states.
class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          readOnly: readOnly,
          onChanged: onChanged,
          focusNode: focusNode,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF202020),
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            errorText: errorText,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFFCCCCCC),
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF999999),
              size: 22,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFF2B2B2B),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFEF5350),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
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
        ),
      ),
    );
  }
}
