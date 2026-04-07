import 'package:flutter/material.dart';

/// A fully-styled dialog that matches the app's design system.
///
/// Features:
/// - Professional visual hierarchy with colors and typography
/// - Dark theme support
/// - Proper spacing and padding
/// - Styled action buttons (primary/secondary, including destructive variants)
/// - Optional warning box for critical actions
/// - Better visual depth and polish
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (ctx) => StyledDialog(
///     title: 'Delete Item',
///     content: Text('Are you sure?'),
///     actions: [
///       StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
///       StyledDialogAction(label: 'Delete', isPrimary: true, isDestructive: true, onPressed: () => ...),
///     ],
///   ),
/// );
/// ```
class StyledDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<StyledDialogAction> actions;
  final Widget? warningBox;

  const StyledDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    required this.actions,
    this.warningBox,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202020),
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Warning Box (optional)
            if (warningBox != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: warningBox,
              ),
            ],
            // Content Section with styled background
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8E8E8),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFEEEEEE),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            // Actions Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: actions[i].isPrimary
                          ? _buildPrimaryButton(actions[i])
                          : _buildSecondaryButton(actions[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(StyledDialogAction action) {
    final bgColor = action.isDestructive ? const Color(0xFFEF5350) : const Color(0xFF2B2B2B);

    return FilledButton(
      onPressed: action.onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        action.label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(StyledDialogAction action) {
    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF666666),
        side: const BorderSide(
          color: Color(0xFFE0E0E0),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        action.label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// Represents an action button in a [StyledDialog].
class StyledDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const StyledDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

/// Helper extension to create styled text input fields for dialogs
extension StyledTextFieldDecoration on InputDecoration {
  static InputDecoration styled({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF999999),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFFCCCCCC),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF2B2B2B),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFEF5350),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
