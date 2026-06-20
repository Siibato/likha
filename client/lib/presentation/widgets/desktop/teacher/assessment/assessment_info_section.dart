import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/formatters.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_info_row.dart';

class AssessmentInfoSection extends StatelessWidget {
  final Assessment assessment;

  const AssessmentInfoSection({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          if (assessment.description != null &&
              assessment.description!.isNotEmpty) ...[
            Text(
              assessment.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
          ],
          AssessmentInfoRow(
            icon: Icons.timer_rounded,
            label: 'Time Limit',
            value: assessment.timeLimitMinutes > 0
                ? '${assessment.timeLimitMinutes} minutes'
                : 'No limit',
          ),
          AssessmentInfoRow(
            icon: Icons.stars_rounded,
            label: 'Total Points',
            value: '${assessment.totalPoints}',
          ),
          AssessmentInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Open Date',
            value: formatDateTimeDisplay(assessment.openAt),
          ),
          AssessmentInfoRow(
            icon: Icons.event_rounded,
            label: 'Close Date',
            value: formatDateTimeDisplay(assessment.closeAt),
          ),
          AssessmentInfoRow(
            icon: Icons.people_rounded,
            label: 'Submissions',
            value: '${assessment.submissionCount}',
          ),
          AssessmentInfoRow(
            icon: Icons.grading_rounded,
            label: 'Results Released',
            value: assessment.resultsReleased ? 'Yes' : 'No',
            isLast: true,
          ),
        ],
      ),
    );
  }
}
