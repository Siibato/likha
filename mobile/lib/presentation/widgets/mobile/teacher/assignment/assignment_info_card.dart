import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssignmentInfoCard extends StatelessWidget {
  final int totalPoints;
  final String submissionType;
  final String? allowedFileTypes;
  final int? maxFileSizeMb;
  final DateTime dueAt;
  final DateTime createdAt;

  const AssignmentInfoCard({
    super.key,
    required this.totalPoints,
    required this.submissionType,
    this.allowedFileTypes,
    this.maxFileSizeMb,
    required this.dueAt,
    required this.createdAt,
  });

  String _submissionTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Text Only';
      case 'file':
        return 'File Only';
      case 'text_or_file':
        return 'Text and/or File';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.star_outline_rounded,
            label: 'Total Points',
            value: '$totalPoints points',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.upload_file_rounded,
            label: 'Submission Type',
            value: _submissionTypeLabel(submissionType),
          ),
          if (allowedFileTypes != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.file_present_rounded,
              label: 'Allowed Files',
              value: allowedFileTypes!,
            ),
          ],
          if (maxFileSizeMb != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.sd_storage_rounded,
              label: 'Max File Size',
              value: '$maxFileSizeMb MB',
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'Due Date',
            value: _formatDateTime(dueAt),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Created',
            value: _formatDateTime(createdAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.foregroundSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.accentCharcoal,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}