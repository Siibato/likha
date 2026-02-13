import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class SubmissionCard extends StatelessWidget {
  final String studentName;
  final String status;
  final bool isLate;
  final int? score;
  final int totalPoints;
  final DateTime? submittedAt;
  final VoidCallback onTap;

  const SubmissionCard({
    super.key,
    required this.studentName,
    required this.status,
    required this.isLate,
    this.score,
    required this.totalPoints,
    this.submittedAt,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return AppColors.foregroundTertiary;
      case 'submitted':
        return AppColors.foregroundSecondary;
      case 'graded':
        return AppColors.foregroundPrimary;
      case 'returned':
        return AppColors.foregroundSecondary;
      default:
        return AppColors.foregroundTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      case 'returned':
        return 'Returned';
      default:
        return status;
    }
  }

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
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundTertiary,
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.foregroundPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202020),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.semanticError.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Late',
                              style: TextStyle(
                                color: AppColors.semanticError,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (score != null)
                          Text(
                            '$score/$totalPoints pts',
                            style: const TextStyle(
                              color: AppColors.foregroundSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (submittedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${_formatDateTime(submittedAt!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.foregroundTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.borderLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}