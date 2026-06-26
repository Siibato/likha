import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';

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
  late final FleatherController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);

    final content = widget.initialContent;
    if (content != null && content.isNotEmpty) {
      try {
        final doc = ParchmentDocument.fromJson(jsonDecode(content));
        _contentController = FleatherController(document: doc);
      } catch (_) {
        _contentController = FleatherController();
      }
    } else {
      _contentController = FleatherController();
    }
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

    final contentPlainText = _contentController.document.toPlainText().trim();
    final contentJson = contentPlainText.isEmpty
        ? null
        : jsonEncode(_contentController.document.toJson());
    ref.read(learningMaterialProvider.notifier).updateMaterial(
      materialId: widget.materialId,
      title: newTitle,
      description: null,
      contentText: contentJson,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Edit Module',
      maxWidth: 680,
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: StyledTextFieldDecoration.styled(
              labelText: 'Title',
            ),
          ),
          const SizedBox(height: 16),
          RichTextField(
            controller: _contentController,
            label: 'Content (Optional)',
            icon: Icons.description_outlined,
            minHeight: 350,
          ),
        ],
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
