import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/labels.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';

/// Info section showing assignment metadata (points, type, dates).
class AssignmentInfoSection extends StatelessWidget {
  final Assignment assignment;

  const AssignmentInfoSection({super.key, required this.assignment});

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
            'Assignment Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.stars_rounded,
            label: 'Total Points',
            value: '${assignment.totalPoints}',
          ),
          _InfoRow(
            icon: Icons.upload_file_rounded,
            label: 'Submission Type',
            value: submissionTypeFromBools(
              assignment.allowsTextSubmission,
              assignment.allowsFileSubmission,
            ),
          ),
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Due Date',
            value: _formatDateTime(assignment.dueAt),
          ),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Created',
            value: _formatDateTime(assignment.createdAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.foregroundTertiary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
