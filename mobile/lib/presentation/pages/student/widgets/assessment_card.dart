import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

enum AssessmentStatus {
  notYetOpen,
  available,
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
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final canTap = status == AssessmentStatus.available ||
        (status == AssessmentStatus.submitted &&
            (assessment.resultsReleased || assessment.showResultsImmediately));

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
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
              if (canTap) ...[
                const SizedBox(height: 12),
                _buildActionHint(),
              ],
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
              color: Color(0xFF202020),
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _statusIcon(status),
                size: 14,
                color: const Color(0xFF666666),
              ),
              const SizedBox(width: 5),
              Text(
                _statusLabel(status),
                style: const TextStyle(
                  color: Color(0xFF666666),
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
        color: Color(0xFF666666),
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
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status == AssessmentStatus.submitted
                ? 'Tap to view results'
                : 'Tap to start',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFFFBD59),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Color(0xFFFFBD59),
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
        Icon(icon, size: 15, color: const Color(0xFF666666)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
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
        Icon(icon, size: 13, color: const Color(0xFF999999)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          dateTime,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}