import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.accentCharcoal,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.accentCharcoal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_outline_rounded,
                          size: 14,
                          color: AppColors.foregroundSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$totalPoints pts',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.foregroundSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: AppColors.foregroundSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDateTime(dueAt),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.foregroundSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
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
                          const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
                        ],
                        if (isPastDue && submissionStatus == null) ...[
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
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.borderLight,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}