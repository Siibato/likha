import 'package:flutter/material.dart';

class AssessmentDialogs {
  static void showExitWarning(
    BuildContext context, {
    required VoidCallback onLeave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave Assessment?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        content: const Text(
          'If you leave, the timer will continue running. Your answers are saved periodically. Are you sure you want to leave?',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onLeave();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEA4335),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  static void showSubmitConfirmation(
    BuildContext context, {
    required VoidCallback onSubmit,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Submit Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        content: const Text(
          'Are you sure you want to submit? You will not be able to change your answers after submission.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSubmit();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  static void showStartConfirmation(
    BuildContext context, {
    required int timeLimitMinutes,
    required int questionCount,
    required VoidCallback onStart,
  }) {
    // Format time label (e.g. "30 min", "1 hr 30 min")
    final timeLabel = timeLimitMinutes >= 60
        ? () {
            final h = timeLimitMinutes ~/ 60;
            final m = timeLimitMinutes % 60;
            return m == 0
                ? '$h hr${h > 1 ? 's' : ''}'
                : '$h hr${h > 1 ? 's' : ''} $m min';
          }()
        : '$timeLimitMinutes min';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Start Assessment?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        content: Text(
          'You have $questionCount question${questionCount != 1 ? 's' : ''} '
          'and a time limit of $timeLabel. '
          'Once started, the timer cannot be paused.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF666666)),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onStart();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}