import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessment_question_card.dart';

class AssessmentQuestionsSection extends StatelessWidget {
  final List<Question> questions;

  const AssessmentQuestionsSection({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${questions.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                'No questions added yet',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                AssessmentQuestionCard(
                  question: questions[index],
                  number: index + 1,
                ),
          ),
      ],
    );
  }
}
