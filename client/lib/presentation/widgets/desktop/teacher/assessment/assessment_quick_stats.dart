import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_stat_row.dart';

class AssessmentQuickStats extends StatelessWidget {
  final Assessment assessment;
  final List<Question> questions;

  const AssessmentQuickStats({
    super.key,
    required this.assessment,
    required this.questions,
  });

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
            'Quick Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          AssessmentStatRow(
            label: 'Submissions',
            value: '${assessment.submissionCount}',
          ),
          const SizedBox(height: 12),
          AssessmentStatRow(
            label: 'Questions',
            value: '${questions.length}',
          ),
          const SizedBox(height: 12),
          AssessmentStatRow(
            label: 'Total Points',
            value: '${assessment.totalPoints}',
          ),
        ],
      ),
    );
  }
}
