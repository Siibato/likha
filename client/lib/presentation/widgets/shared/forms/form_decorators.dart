import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Shared input decoration for assessment forms (mobile + desktop).
InputDecoration assessmentInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle:
        const TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
