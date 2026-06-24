import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class AssessmentDetailActionsMenu extends ConsumerWidget {
  final Assessment assessment;
  final String assessmentId;

  const AssessmentDetailActionsMenu({
    super.key,
    required this.assessment,
    required this.assessmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.foregroundDark),
      onSelected: (value) => _handleMenuAction(context, ref, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: assessment.isPublished ? 'unpublish' : 'publish',
          child: Row(
            children: [
              Icon(
                assessment.isPublished
                    ? Icons.unpublished_rounded
                    : Icons.publish_rounded,
                size: 18,
                color: AppColors.foregroundSecondary,
              ),
              const SizedBox(width: 12),
              Text(assessment.isPublished ? 'Unpublish' : 'Publish'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'release_results',
          enabled: !assessment.resultsReleased,
          child: Row(
            children: [
              Icon(
                Icons.grading_rounded,
                size: 18,
                color: assessment.resultsReleased
                    ? AppColors.foregroundTertiary
                    : AppColors.foregroundSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Release Results',
                style: TextStyle(
                  color: assessment.resultsReleased
                      ? AppColors.foregroundTertiary
                      : null,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded,
                  size: 18, color: AppColors.semanticError),
              SizedBox(width: 12),
              Text('Delete',
                  style: TextStyle(color: AppColors.semanticError)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'publish':
        AppDialogs.showConfirmation(
          context: context,
          title: 'Publish Assessment',
          body:
              'This will make the assessment visible to students. Are you sure?',
          confirmLabel: 'Publish',
          onConfirm: () => ref
              .read(assessmentListProvider.notifier)
              .publishAssessment(assessmentId),
        );
        break;
      case 'unpublish':
        AppDialogs.showDestructive(
          context: context,
          title: 'Unpublish Assessment',
          body:
              'This will hide the assessment from students. Existing submissions will be kept.',
          confirmLabel: 'Unpublish',
          onConfirm: () => ref
              .read(assessmentListProvider.notifier)
              .unpublishAssessment(assessmentId),
        );
        break;
      case 'release_results':
        AppDialogs.showConfirmation(
          context: context,
          title: 'Release Results',
          body:
              'Students will be able to see their scores and answers. This cannot be undone.',
          confirmLabel: 'Release',
          onConfirm: () => ref
              .read(assessmentDetailProvider.notifier)
              .releaseResults(assessmentId),
        );
        break;
      case 'delete':
        AppDialogs.showDestructive(
          context: context,
          title: 'Delete Assessment',
          body:
              'This will permanently delete the assessment and all its questions. This cannot be undone.',
          confirmLabel: 'Delete',
          onConfirm: () => ref
              .read(assessmentListProvider.notifier)
              .deleteAssessment(assessmentId),
        );
        break;
    }
  }
}
