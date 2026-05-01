import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Card showing assessment description, stat chips (points, time, questions),
/// and open/close date rows.
class AssessmentInfoCard extends StatelessWidget {
  final String? description;
  final int totalPoints;
  final int timeLimitMinutes;
  final int questionCount;
  final DateTime openAt;
  final DateTime closeAt;

  const AssessmentInfoCard({
    super.key,
    this.description,
    required this.totalPoints,
    required this.timeLimitMinutes,
    required this.questionCount,
    required this.openAt,
    required this.closeAt,
  });

  String _formatTimeLimit(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (remaining == 0) return '$hours hr${hours > 1 ? 's' : ''}';
      return '$hours hr${hours > 1 ? 's' : ''} $remaining min';
    }
    return '$minutes min';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description!.isNotEmpty) ...[
              Text(
                description!,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.accentCharcoal,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _InfoChip(
                  icon: Icons.star_outline_rounded,
                  label: '$totalPoints pts',
                ),
                const SizedBox(width: 14),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: _formatTimeLimit(timeLimitMinutes),
                ),
                const SizedBox(width: 14),
                _InfoChip(
                  icon: Icons.help_outline_rounded,
                  label:
                      '$questionCount question${questionCount != 1 ? 's' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DateRow(
              icon: Icons.calendar_today_rounded,
              label: 'Opens',
              dateTime: _formatDateTime(openAt),
            ),
            const SizedBox(height: 6),
            _DateRow(
              icon: Icons.event_rounded,
              label: 'Closes',
              dateTime: _formatDateTime(closeAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.foregroundSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String dateTime;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.foregroundTertiary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.foregroundTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          dateTime,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.foregroundSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
