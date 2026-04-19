import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';

class AssessmentDialogs {
  static Future<void> showExitWarning(
    BuildContext context, {
    required VoidCallback onLeave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Leave Assessment?',
        content: const Text(
          'Your progress will be saved, but the timer will continue running.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          StyledDialogAction(label: 'Stay', onPressed: () => Navigator.pop(ctx)),
          StyledDialogAction(
            label: 'Leave',
            isPrimary: true,
            isDestructive: true,
            onPressed: () { Navigator.pop(ctx); onLeave(); },
          ),
        ],
      ),
    );
  }

  static Future<void> showSubmitConfirmation(
    BuildContext context, {
    required VoidCallback onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Submit Assessment',
        content: const Text(
          'Are you sure you want to submit? You cannot change your answers after submission.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          StyledDialogAction(
            label: 'Submit',
            isPrimary: true,
            onPressed: () { Navigator.pop(ctx); onSubmit(); },
          ),
        ],
      ),
    );
  }

  static Future<void> showStartConfirmation(
    BuildContext context, {
    required int timeLimitMinutes,
    required int questionCount,
    required VoidCallback onStart,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Start Assessment',
        content: Text(
          'This assessment has $questionCount question${questionCount != 1 ? 's' : ''} with a $timeLimitMinutes-minute time limit. Once started, the timer cannot be paused.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          StyledDialogAction(
            label: 'Start',
            isPrimary: true,
            onPressed: () { Navigator.pop(ctx); onStart(); },
          ),
        ],
      ),
    );
  }
}