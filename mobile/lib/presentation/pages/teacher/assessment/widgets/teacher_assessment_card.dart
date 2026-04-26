import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card_sm.dart';

class TeacherAssessmentCard extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback onTap;

  const TeacherAssessmentCard({
    super.key,
    required this.assessment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCardSm(
      onTap: onTap,
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 14),
          Expanded(child: _buildContent()),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.foregroundLight,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: assessment.isPublished
            ? AppColors.borderLight
            : AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        assessment.isPublished ? Icons.public_rounded : Icons.edit_note_rounded,
        color: assessment.isPublished
            ? AppColors.accentCharcoal
            : AppColors.foregroundTertiary,
        size: 20,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assessment.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${assessment.questionCount} questions • ${assessment.totalPoints} pts • ${assessment.submissionCount} submissions',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.foregroundTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}