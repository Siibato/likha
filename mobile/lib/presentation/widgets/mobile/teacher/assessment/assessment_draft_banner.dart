import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Inline banner shown when a saved draft is being resumed.
///
/// Displays a "Resuming draft" label and a "Discard" action.
class AssessmentDraftBanner extends StatelessWidget {
  final VoidCallback onDiscard;

  const AssessmentDraftBanner({super.key, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDisabled,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore_rounded, size: 16, color: AppColors.foregroundSecondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Resuming draft',
              style: TextStyle(fontSize: 13, color: AppColors.foregroundSecondary),
            ),
          ),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.semanticError,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
