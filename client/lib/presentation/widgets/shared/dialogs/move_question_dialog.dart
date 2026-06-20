import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

class MoveQuestionDialog extends StatefulWidget {
  final int currentIndex;
  final int questionCount;
  final void Function(int fromIndex, int toIndex) onMove;

  const MoveQuestionDialog({
    super.key,
    required this.currentIndex,
    required this.questionCount,
    required this.onMove,
  });

  @override
  State<MoveQuestionDialog> createState() => _MoveQuestionDialogState();
}

class _MoveQuestionDialogState extends State<MoveQuestionDialog> {
  late final TextEditingController _posController;

  @override
  void initState() {
    super.initState();
    _posController = TextEditingController();
  }

  @override
  void dispose() {
    _posController.dispose();
    super.dispose();
  }

  void _handleMove() {
    final newPos = int.tryParse(_posController.text);
    if (newPos != null && newPos >= 1 && newPos <= widget.questionCount) {
      widget.onMove(widget.currentIndex, newPos - 1);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Move Question',
      subtitle:
          'Question ${widget.currentIndex + 1} of ${widget.questionCount}',
      content: TextField(
        controller: _posController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofocus: true,
        decoration: StyledTextFieldDecoration.styled(
          labelText: 'New position (1-${widget.questionCount})',
        ),
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
