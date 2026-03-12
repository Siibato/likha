import 'package:flutter/material.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';

typedef OnReorderCallback = void Function(int currentIndex, int newIndex);

class ReorderPositionDialog extends StatefulWidget {
  final String resourceType;
  final int totalCount;
  final int currentPosition;
  final OnReorderCallback onReorder;

  const ReorderPositionDialog({
    super.key,
    required this.resourceType,
    required this.totalCount,
    required this.currentPosition,
    required this.onReorder,
  });

  @override
  State<ReorderPositionDialog> createState() => _ReorderPositionDialogState();
}

class _ReorderPositionDialogState extends State<ReorderPositionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: (widget.currentPosition + 1).toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleMove() {
    final newPosition = int.tryParse(_controller.text);
    if (newPosition != null && newPosition >= 1 && newPosition <= widget.totalCount) {
      Navigator.pop(context);
      widget.onReorder(widget.currentPosition, newPosition - 1);
    } else {
      context.showErrorSnackBar('Please enter a number between 1 and ${widget.totalCount}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Move to Position',
      subtitle: 'Reorder ${widget.resourceType}',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${widget.resourceType}: ${widget.totalCount}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202020),
            ),
            decoration: StyledTextFieldDecoration.styled(
              labelText: 'Position (1-${widget.totalCount})',
            ),
          ),
        ],
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Move',
          isPrimary: true,
          onPressed: _handleMove,
        ),
      ],
    );
  }
}
