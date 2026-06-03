import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/rich_text_field.dart';

/// Dialog for editing a learning material's title, description, and content.
///
/// Promoted from the private `_EditMaterialDialog` class that previously
/// lived inside `material_detail_page.dart`.
class EditMaterialDialog extends ConsumerStatefulWidget {
  final dynamic material;

  const EditMaterialDialog({super.key, required this.material});

  @override
  ConsumerState<EditMaterialDialog> createState() => _EditMaterialDialogState();
}

class _EditMaterialDialogState extends ConsumerState<EditMaterialDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final FleatherController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.material.title as String);
    _descController =
        TextEditingController(text: (widget.material.description ?? '') as String);

    final contentText = widget.material.contentText as String?;
    if (contentText != null && contentText.isNotEmpty) {
      try {
        final doc =
            ParchmentDocument.fromJson(jsonDecode(contentText));
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
    _descController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    Navigator.pop(context);

    final contentPlainText =
        _contentController.document.toPlainText().trim();
    final contentJson = contentPlainText.isEmpty
        ? null
        : jsonEncode(_contentController.document.toJson());

    await ref.read(learningMaterialProvider.notifier).updateMaterial(
      materialId: widget.material.id as String,
      title: newTitle,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      contentText: contentJson,
    );

    if (!mounted) return;

    final state = ref.read(learningMaterialProvider);
    final errMsg = AppErrorMapper.toUserMessage(state.error);
    if (errMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg)),
      );
    }
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
              controller: _descController,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            RichTextField(
              controller: _contentController,
              label: 'Content (Optional)',
              icon: Icons.description_outlined,
              minHeight: 150,
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
