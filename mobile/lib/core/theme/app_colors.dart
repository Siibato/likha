import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundPrimary = Color(0xFFFFFFFF);

  static const Color backgroundSecondary = Color(0xFFFAFAFA);

  static const Color backgroundTertiary = Color(0xFFF8F9FA);

  static const Color backgroundDisabled = Color(0xFFF5F5F5);

  static const Color foregroundPrimary = Color(0xFF2B2B2B);

  static const Color foregroundSecondary = Color(0xFF666666);

  static const Color foregroundTertiary = Color(0xFF999999);

  static const Color foregroundLight = Color(0xFFAAAAAA);

  static const Color foregroundDark = Color(0xFF202020);

  /// Dark pencil-like border - Focused input fields, primary borders
  static const Color borderPrimary = Color(0xFF2B2B2B);

  /// Medium gray border - Secondary borders, subtle dividers
  static const Color borderSecondary = Color(0xFF666666);

  /// Light gray border - Very subtle borders, light dividers
  static const Color borderLight = Color(0xFFE0E0E0);

  static const Color accentPrimary = Color(0xFF666666);

  static const Color accentSecondary = Color(0xFF999999);

  static const Color semanticError = Color(0xFFEA4335);

  static const Color semanticErrorDark = Color(0xFFDC3545);

  static const Color semanticErrorBackground = Color(0xFFFEEBEE);

  // ============ SEMANTIC - SUCCESS / POSITIVE ============
  /// Success color - Positive states, passing grades
  static const Color semanticSuccess = Color(0xFF34A853);

  /// Success variant - Alternative success color
  static const Color semanticSuccessAlt = Color(0xFF4CAF50);

  /// Success background - Success message backgrounds, success containers
  static const Color semanticSuccessBackground = Color(0xFFE8F5E9);

  // ============ DEPRECATED - TO BE REPLACED ============
  /// Deprecated: Orange used for Draft states - Replace with accentPrimary
  static const Color deprecatedDraftOrange = Color(0xFFFFA726);

  /// Deprecated: Yellow used for timer warnings - Replace with accentSecondary
  static const Color deprecatedWarningYellow = Color(0xFFFFBD59);

  /// Deprecated: Blue used for Published states - Replace with foregroundSecondary
  static const Color deprecatedPublishedBlue = Color(0xFF42A5F5);

  /// Deprecated: Green used for Published-Open - Replace with foregroundSecondary/accentPrimary
  static const Color deprecatedPublishedGreen = Color(0xFF4CAF50);
}
