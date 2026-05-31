import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

/// Dialog for a teacher to override the auto-graded result of a single answer.
class OverrideGradeDialog extends StatefulWidget {
  final SubmissionAnswer answer;
  final void Function(bool isCorrect, double points) onConfirm;

  const OverrideGradeDialog({
    super.key,
    required this.answer,
    required this.onConfirm,
  });

  @override
  State<OverrideGradeDialog> createState() => _OverrideGradeDialogState();
}

class _OverrideGradeDialogState extends State<OverrideGradeDialog> {
  late final TextEditingController _pointsController;
  bool _isCorrect = true;
  bool _showPointsInput = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _pointsController = TextEditingController();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    double? points;
    if (_isCorrect) {
      final raw = _pointsController.text.trim();
      final pts = double.tryParse(raw);
      if (pts == null || pts < 0 || pts > widget.answer.points) {
        setState(() => _validationError =
            'Enter a valid score between 0 and ${widget.answer.points}');
        return;
      }
      points = pts;
    } else {
      points = 0.0;
    }
    setState(() => _validationError = null);
    Navigator.of(context).pop();
    widget.onConfirm(_isCorrect, points);
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Override Grade',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<bool>(
            title: const Text('Mark as Incorrect (0 points)'),
            value: false,
            groupValue: _isCorrect,
            onChanged: (value) {
              setState(() {
                _isCorrect = value!;
                _showPointsInput = false;
                _validationError = null;
              });
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          RadioListTile<bool>(
            title: const Text('Mark as Correct (specify points)'),
            value: true,
            groupValue: _isCorrect,
            onChanged: (value) {
              setState(() {
                _isCorrect = value!;
                _showPointsInput = true;
                _validationError = null;
              });
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (_showPointsInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _pointsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Points (0 – ${widget.answer.points})',
                labelStyle: const TextStyle(
                    fontSize: 13, color: AppColors.foregroundTertiary),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.foregroundPrimary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.semanticError, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.semanticError, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                errorText: _validationError,
              ),
            ),
          ],
        ],
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        StyledDialogAction(
          label: 'Confirm',
          isPrimary: true,
          onPressed: _handleConfirm,
        ),
      ],
    );
  }
}
