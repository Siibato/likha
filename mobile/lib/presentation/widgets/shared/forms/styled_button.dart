import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Button style variants
enum StyledButtonVariant {
  primary,
  outlined,
  destructive,
  dark,
  accent,
}

/// A styled button widget that matches the app's design system.
///
/// Supports multiple variants (primary, outlined, destructive) and optional icon prefix.
/// Provides loading state with spinner feedback.
class StyledButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final StyledButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  const StyledButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    this.variant = StyledButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = _getColors();

    final button = Container(
      decoration: BoxDecoration(
        color: isLoading ? AppColors.borderLight : bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading ? AppColors.backgroundDisabled : bgColor,
            foregroundColor: fgColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.foregroundTertiary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  /// Returns (backgroundColor, foregroundColor) tuple based on variant.
  (Color, Color) _getColors() {
    return switch (variant) {
      StyledButtonVariant.primary => (AppColors.accentCharcoal, Colors.white),
      StyledButtonVariant.dark => (AppColors.accentCharcoal, Colors.white),
      StyledButtonVariant.accent => (AppColors.accentAmber, Colors.white),
      StyledButtonVariant.destructive => (AppColors.semanticError, Colors.white),
      StyledButtonVariant.outlined => (Colors.transparent, AppColors.foregroundSecondary),
    };
  }
}
