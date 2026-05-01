import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

enum AssessmentStatus {
  notYetOpen,
  available,
  inProgress,
  closed,
  submitted,
}

class AssessmentCard extends StatelessWidget {
  final Assessment assessment;
  final AssessmentStatus status;
  final VoidCallback? onTap;

  const AssessmentCard({
    super.key,
    required this.assessment,
    required this.status,
    this.onTap,
  });

  String _statusLabel(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.notYetOpen:
        return 'Not Yet Open';
      case AssessmentStatus.available:
        return 'Available';
      case AssessmentStatus.inProgress:
        return 'In Progress';
      case AssessmentStatus.closed:
        return 'Closed';
      case AssessmentStatus.submitted:
        return 'Submitted';
    }
  }

  IconData _statusIcon(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.notYetOpen:
        return Icons.schedule_rounded;
      case AssessmentStatus.available:
        return Icons.play_circle_outline_rounded;
      case AssessmentStatus.inProgress:
        return Icons.play_circle_rounded;
      case AssessmentStatus.closed:
        return Icons.lock_outline_rounded;
      case AssessmentStatus.submitted:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _formatTimeLimit(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (remaining == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              _buildHeader(),
              if (assessment.description != null &&
                  assessment.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildDescription(),
              ],
              const SizedBox(height: 16),
              _buildInfoRow(),
              const SizedBox(height: 12),
              _buildDateInfo(),
              const SizedBox(height: 12),
              _buildActionHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            assessment.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _statusIcon(status),
                size: 14,
                color: AppColors.foregroundSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                _statusLabel(status),
                style: const TextStyle(
                  color: AppColors.foregroundSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      assessment.description!,
      style: const TextStyle(
        color: AppColors.foregroundSecondary,
        fontSize: 14,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.star_outline_rounded,
          label: '${assessment.totalPoints} pts',
        ),
        const SizedBox(width: 14),
        _InfoChip(
          icon: Icons.timer_outlined,
          label: _formatTimeLimit(assessment.timeLimitMinutes),
        ),
        const SizedBox(width: 14),
        _InfoChip(
          icon: Icons.help_outline_rounded,
          label:
              '${assessment.questionCount} question${assessment.questionCount != 1 ? 's' : ''}',
        ),
      ],
    );
  }

  Widget _buildDateInfo() {
    return Column(
      children: [
        _DateRow(
          icon: Icons.calendar_today_rounded,
          label: 'Opens',
          dateTime: _formatDateTime(assessment.openAt),
        ),
        const SizedBox(height: 6),
        _DateRow(
          icon: Icons.event_rounded,
          label: 'Closes',
          dateTime: _formatDateTime(assessment.closeAt),
        ),
      ],
    );
  }

  Widget _buildActionHint() {
    final hintText = switch (status) {
      AssessmentStatus.submitted => 'Tap to view details',
      AssessmentStatus.available => 'Tap to start',
      AssessmentStatus.inProgress => 'Tap to resume',
      _ => 'Tap to view details',
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hintText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppColors.foregroundSecondary,
          ),
        ],
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
        Icon(icon, size: 15, color: AppColors.foregroundSecondary,),
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
        Icon(icon, size: 13, color: AppColors.foregroundTertiary,),
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