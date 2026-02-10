import 'package:flutter/material.dart';

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
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: 4,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2B2B2B),
      ),
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF999999),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Icon(
            Icons.description_outlined,
            color: Color(0xFF666666),
            size: 20,
          ),
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
    );
  }
}