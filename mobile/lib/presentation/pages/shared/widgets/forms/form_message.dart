import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Severity level for form-level messages.
enum MessageSeverity { error, warning, info, success }

/// A styled form-level message widget.
///
/// Replaces snackbars for form feedback. Displays inline on the screen
/// with contextual icon and color based on severity.
/// Hidden when [message] is null.
class FormMessage extends StatelessWidget {
  final String? message;
  final MessageSeverity severity;

  const FormMessage({
    super.key,
    this.message,
    this.severity = MessageSeverity.error,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final (backgroundColor, textColor, iconData) = _getColors();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color background, Color text, IconData icon) _getColors() {
    return switch (severity) {
      MessageSeverity.error => (
          AppColors.semanticErrorBackground,
          AppColors.semanticError,
          Icons.error_rounded,
        ),
      MessageSeverity.warning => (
          AppColors.accentAmber.withValues(alpha: 0.1),
          AppColors.accentAmber,
          Icons.warning_rounded,
        ),
      MessageSeverity.info => (
          AppColors.accentCharcoal.withValues(alpha: 0.1),
          AppColors.accentCharcoal,
          Icons.info_rounded,
        ),
      MessageSeverity.success => (
          AppColors.semanticSuccessBackground,
          AppColors.semanticSuccess,
          Icons.check_circle_rounded,
        ),
    };
  }
}
