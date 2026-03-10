import 'package:flutter/material.dart';
import 'package:likha/core/config/app_config.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Extension on BuildContext providing centralized snackbar display methods.
/// All snackbars are gated by AppConfig.isDev — when dev mode is off, they silently return.
///
/// Usage:
///   context.showErrorSnackBar('An error occurred');
///   context.showSuccessSnackBar('Saved successfully', durationMs: 2000);
///   context.showInfoSnackBar('Downloading...', durationMs: 3000);
///   context.showWarningSnackBar('File not found. Re-downloading...', durationMs: 2000);
extension SnackBarExtension on BuildContext {
  /// Show red error snackbar (4s default).
  /// Use for API errors, validation failures, and exceptions.
  void showErrorSnackBar(String message, {int durationMs = 4000}) {
    if (!AppConfig.isDev) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.semanticError,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: durationMs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show green success snackbar (2s default).
  /// Use for saves, submits, creates, and completions.
  void showSuccessSnackBar(String message, {int durationMs = 2000}) {
    if (!AppConfig.isDev) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.semanticSuccess,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: durationMs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show dark gray info snackbar (3s default).
  /// Use for download progress, neutral feedback, and status updates.
  void showInfoSnackBar(String message, {int durationMs = 3000}) {
    if (!AppConfig.isDev) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.foregroundPrimary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: durationMs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show orange warning snackbar (4s default).
  /// Use for re-download notices, non-critical alerts, and warnings.
  void showWarningSnackBar(String message, {int durationMs = 4000}) {
    if (!AppConfig.isDev) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.deprecatedDraftOrange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: durationMs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
