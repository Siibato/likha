import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';
import '../forms/styled_text_field.dart';

/// Static helper class for displaying common dialog patterns.
///
/// All methods internally call [showDialog] with [StyledDialog] builder.
/// Provides convenient factory methods for confirmation, destructive, input, and info dialogs.
abstract final class AppDialogs {
  /// Shows a confirmation dialog with two buttons (Cancel and Confirm).
  ///
  /// The confirm button is primary (dark background).
  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String cancelLabel = 'Cancel',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: title,
        content: Text(body),
        actions: [
          StyledDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: confirmLabel,
            isPrimary: true,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  /// Shows a destructive action dialog with red confirm button.
  ///
  /// Optionally displays a warning box between the title and content.
  static Future<void> showDestructive({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String cancelLabel = 'Cancel',
    Widget? warningBox,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: title,
        warningBox: warningBox,
        content: Text(body),
        actions: [
          StyledDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: confirmLabel,
            isPrimary: true,
            isDestructive: true,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  /// Shows a text input dialog with a single text field.
  ///
  /// Provides cancel and confirm buttons. The confirm button is primary.
  static Future<void> showInput({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required String labelText,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String? subtitle,
    String cancelLabel = 'Cancel',
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: title,
        subtitle: subtitle,
        content: StyledTextField(
          controller: controller,
          label: labelText,
          icon: Icons.edit_rounded,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
        actions: [
          StyledDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: confirmLabel,
            isPrimary: true,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  /// Shows an info dialog with a single OK button.
  ///
  /// Used for non-critical messages and confirmations.
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String body,
    String confirmLabel = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: title,
        content: Text(body),
        actions: [
          StyledDialogAction(
            label: confirmLabel,
            isPrimary: true,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}
