import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

/// Dialog for editing a competency in a TOS.
///
/// Uses the provided [TextEditingController]s so the caller can prepopulate
/// them before showing the dialog.
class EditCompetencyDialog extends StatelessWidget {
  final TextEditingController competencyController;
  final TextEditingController daysTaughtController;
  final String unitLabel;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const EditCompetencyDialog({
    super.key,
    required this.competencyController,
    required this.daysTaughtController,
    required this.unitLabel,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Edit Competency',
      leadingAction: onDelete != null
          ? StyledDialogAction(
              label: 'Delete',
              onPressed: () {
                Navigator.pop(context);
                onDelete!();
              },
            )
          : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledTextField(
            controller: competencyController,
            label: 'Competency description',
            icon: Icons.edit_rounded,
          ),
          const SizedBox(height: 12),
          StyledTextField(
            controller: daysTaughtController,
            label: '$unitLabel taught',
            icon: Icons.schedule_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: '1',
          ),
        ],
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Save',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            onSave();
          },
        ),
      ],
    );
  }
}
