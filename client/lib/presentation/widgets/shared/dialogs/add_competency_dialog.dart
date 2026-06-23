import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

/// Dialog for adding a competency to a TOS.
///
/// Uses the provided [TextEditingController]s so the caller can prepopulate
/// or clear them before showing the dialog.
class AddCompetencyDialog extends StatelessWidget {
  final TextEditingController competencyController;
  final TextEditingController timeUnitsTaughtController;
  final String unitLabel;
  final VoidCallback onAdd;

  const AddCompetencyDialog({
    super.key,
    required this.competencyController,
    required this.timeUnitsTaughtController,
    required this.unitLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Add Competency',
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
            controller: timeUnitsTaughtController,
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
          label: 'Add',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            onAdd();
          },
        ),
      ],
    );
  }
}
