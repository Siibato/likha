import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class AssessmentDetailDeleteSection extends ConsumerWidget {
  final Assessment assessment;
  final String assessmentId;

  const AssessmentDetailDeleteSection({
    super.key,
    required this.assessment,
    required this.assessmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.semanticError,
          side: const BorderSide(
            color: AppColors.semanticError,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(
          Icons.delete_outline_rounded,
          size: 20,
        ),
        label: const Text(
          'Delete Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final hasWarning = assessment.isPublished || assessment.submissionCount > 0;
    final warningBox = hasWarning
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.semanticErrorBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.semanticError.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded,
                    color: AppColors.semanticError, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessment.isPublished
                        ? 'This assessment is published and has ${assessment.submissionCount} submission(s). All data will be lost.'
                        : 'This assessment has ${assessment.submissionCount} submission(s). All data will be lost.',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.semanticErrorDark),
                  ),
                ),
              ],
            ),
          )
        : null;

    AppDialogs.showDestructive(
      context: context,
      title: 'Delete Assessment',
      body: 'Delete "${assessment.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () => ref
          .read(assessmentListProvider.notifier)
          .deleteAssessment(assessmentId),
      warningBox: warningBox,
    );
  }
}
