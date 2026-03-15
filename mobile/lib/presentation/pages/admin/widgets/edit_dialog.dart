import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';

class EditDialog extends StatefulWidget {
  final String title;
  final String currentValue;
  final void Function(String) onSave;

  const EditDialog({
    super.key,
    required this.title,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: widget.title,
      content: Container(
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(14)),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202020),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF2B2B2B),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
      actions: [
        StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        StyledDialogAction(
          label: 'Save',
          isPrimary: true,
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty && value != widget.currentValue) {
              Navigator.pop(context);
              widget.onSave(value);
            }
          },
        ),
      ],
    );
  }
}