import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

/// Desktop dialog for editing a learning material's title and content.
class EditMaterialDialog extends ConsumerStatefulWidget {
  final String materialId;
  final String initialTitle;
  final String? initialContent;

  const EditMaterialDialog({
    super.key,
    required this.materialId,
    required this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<EditMaterialDialog> createState() =>
      _EditMaterialDialogState();
}

class _EditMaterialDialogState extends ConsumerState<EditMaterialDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    Navigator.pop(context);

    final content = _contentController.text.trim();
    ref.read(learningMaterialProvider.notifier).updateMaterial(
      materialId: widget.materialId,
      title: newTitle,
      description: null,
      contentText: content.isEmpty ? null : content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Edit Module',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Content (Optional)',
              ),
              maxLines: 8,
              minLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Save Changes',
          isPrimary: true,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
