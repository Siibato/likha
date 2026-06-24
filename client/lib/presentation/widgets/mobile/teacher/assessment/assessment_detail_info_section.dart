import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/mobile/teacher/assessment/assessment_edit_page.dart';
import 'package:likha/presentation/pages/mobile/teacher/assessment/assessment_statistics_page.dart';
import 'package:likha/presentation/pages/mobile/teacher/assessment/assessment_submissions_page.dart';
import 'package:likha/presentation/pages/mobile/teacher/tos/tos_view_page.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/providers/assessment/assessment_detail_notifier.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_action_buttons.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_info_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/assessment_status_card.dart';
import 'package:likha/presentation/widgets/mobile/teacher/dashboard/view_tos_chip.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class AssessmentDetailInfoSection extends ConsumerWidget {
  final Assessment assessment;
  final String assessmentId;

  const AssessmentDetailInfoSection({
    super.key,
    required this.assessment,
    required this.assessmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssessmentInfoCard(
          description: assessment.description,
          timeLimitMinutes: assessment.timeLimitMinutes,
          totalPoints: assessment.totalPoints,
          questionCount: assessment.questionCount,
          submissionCount: assessment.submissionCount,
          openAt: assessment.openAt,
          closeAt: assessment.closeAt,
          showResultsImmediately: assessment.showResultsImmediately,
          canEdit: !assessment.isPublished,
          onEdit: !assessment.isPublished
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAssessmentPage(
                        assessment: assessment,
                      ),
                    ),
                  )
              : null,
        ),
        const SizedBox(height: 16),
        AssessmentStatusCard(
          isPublished: assessment.isPublished,
          resultsReleased: assessment.resultsReleased,
          onTap: !assessment.isPublished
              ? () => _confirmPublish(context, ref)
              : assessment.isPublished && !assessment.resultsReleased
                  ? () => _confirmReleaseResults(context, ref)
                  : null,
        ),
        if (assessment.tosId != null) ...[
          const SizedBox(height: 16),
          ViewTosChip(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TosViewPage(
                  tosId: assessment.tosId!,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (assessment.isPublished) ...[
          AssessmentActionButtons(
            onViewSubmissions: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentSubmissionsPage(
                  assessmentId: assessmentId,
                ),
              ),
            ),
            onViewStatistics: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentStatisticsPage(
                  assessmentId: assessmentId,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _confirmPublish(BuildContext context, WidgetRef ref) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Publish Assessment',
      body:
          'Publish "${assessment.title}"? Once published, questions can no longer be edited.',
      confirmLabel: 'Publish',
      onConfirm: () => ref
          .read(assessmentListProvider.notifier)
          .publishAssessment(assessmentId),
    );
  }

  void _confirmReleaseResults(BuildContext context, WidgetRef ref) {
    AppDialogs.showConfirmation(
      context: context,
      title: 'Release Results',
      body:
          'Release results for "${assessment.title}"? Students will be able to see their scores.',
      confirmLabel: 'Release',
      onConfirm: () => ref
          .read(assessmentDetailProvider.notifier)
          .releaseResults(assessmentId),
    );
  }
}
