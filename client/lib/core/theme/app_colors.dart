import 'package:flutter/material.dart';

class AppColors {
  // ============ BACKGROUNDS ============
  static const Color backgroundPrimary = Color(0xFFFFFFFF);

  static const Color backgroundSecondary = Color(0xFFFAFAFA);

  static const Color backgroundTertiary = Color(0xFFF8F9FA);

  static const Color backgroundDisabled = Color(0xFFF5F5F5);

  // ============ FOREGROUNDS (NEUTRAL TEXT) ============
  static const Color foregroundPrimary = Color(0xFF2B2B2B);

  static const Color foregroundSecondary = Color(0xFF666666);

  static const Color foregroundTertiary = Color(0xFF999999);

  static const Color foregroundLight = Color(0xFFAAAAAA);

  static const Color foregroundDark = Color(0xFF202020);

  // ============ BORDERS ============
  /// Dark pencil-like border - Focused input fields, primary borders
  static const Color borderPrimary = Color(0xFF2B2B2B);

  /// Medium gray border - Secondary borders, subtle dividers
  static const Color borderSecondary = Color(0xFF666666);

  /// Light gray border - Very subtle borders, light dividers
  static const Color borderLight = Color(0xFFE0E0E0);

  // ============ ACCENT - CHARCOAL ============
  /// Primary accent - CTAs, FABs, card bottom-border depth, prominent card BG, active states
  static const Color accentCharcoal = Color(0xFF333333);

  /// Darker charcoal - Pressed/hover state of charcoal accent
  static const Color accentCharcoalDark = Color(0xFF1A1A1A);

  /// Text/icons on charcoal backgrounds
  static const Color onCharcoal = Color(0xFFFFFFFF);

  // ============ ACCENT - AMBER ============
  /// Secondary accent - Badges, highlights, amber card surfaces, icons on dark cards
  static const Color accentAmber = Color(0xFFFFB703);

  /// Amber border - Darker amber for card/badge outlines
  static const Color accentAmberBorder = Color(0xFFE69C00);

  /// Amber surface - Light amber tinted background for amber-accent cards
  static const Color accentAmberSurface = Color(0xFFFFF8E1);

  /// Text/icons on amber backgrounds
  static const Color onAmber = Color(0xFF1A1A1A);

  // ============ SEMANTIC - ERROR / DESTRUCTIVE ============
  static const Color semanticError = Color(0xFFEA4335);

  static const Color semanticErrorDark = Color(0xFFDC3545);

  static const Color semanticErrorBackground = Color(0xFFFEEBEE);

  // ============ SEMANTIC - SUCCESS / POSITIVE ============
  /// Success color - Passing grades, positive indicators only
  static const Color semanticSuccess = Color(0xFF34A853);

  /// Success variant - Alternative success color for grade indicators
  static const Color semanticSuccessAlt = Color(0xFF4CAF50);

  /// Success background - Success message backgrounds, success containers
  static const Color semanticSuccessBackground = Color(0xFFE8F5E9);

  // ============ DEPRECATED - DO NOT USE ============
  /// Deprecated: Use accentAmber instead
  static const Color deprecatedDraftOrange = Color(0xFFFFA726);

  /// Deprecated: Use accentAmber instead
  static const Color deprecatedWarningYellow = Color(0xFFFFBD59);

  /// Deprecated: Use accentCharcoal instead
  static const Color deprecatedPublishedBlue = Color(0xFF42A5F5);

  /// Deprecated: Use semanticSuccess for grade indicators only
  static const Color deprecatedPublishedGreen = Color(0xFF4CAF50);
}
