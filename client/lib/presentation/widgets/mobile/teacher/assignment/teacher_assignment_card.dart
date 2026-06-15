import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card_sm.dart';

class TeacherAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const TeacherAssignmentCard({
    super.key,
    required this.assignment,
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
        color: assignment.isPublished
            ? AppColors.borderLight
            : AppColors.backgroundDisabled,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        assignment.isPublished
            ? Icons.assignment_turned_in_rounded
            : Icons.assignment_outlined,
        color: assignment.isPublished
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
          assignment.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${assignment.totalPoints} pts • ${assignment.submissionCount} submissions • ${assignment.gradedCount} graded',
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