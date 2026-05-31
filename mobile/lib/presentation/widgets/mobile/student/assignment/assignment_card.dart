import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/cards/base_info_card.dart';

class AssignmentCard extends StatelessWidget {
  final String title;
  final int totalPoints;
  final DateTime dueAt;
  final bool isPastDue;
  final String? submissionStatus;
  final int? score;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.title,
    required this.totalPoints,
    required this.dueAt,
    required this.isPastDue,
    this.submissionStatus,
    this.score,
    required this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return BaseInfoCard(
      title: title,
      subtitle: '$totalPoints pts • Due ${_formatDateTime(dueAt)}',
      icon: const Icon(Icons.assignment_outlined, color: AppColors.accentCharcoal),
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 14),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (submissionStatus == 'graded' && score != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: Text(
                'Score: $score/$totalPoints',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.foregroundSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else if (submissionStatus == 'submitted') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: const Text(
                'Submitted',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.foregroundSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else if (submissionStatus == 'returned') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: const Text(
                'Returned',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.foregroundSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else if (isPastDue && submissionStatus == null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: const Text(
                'Past Due',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.foregroundSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}