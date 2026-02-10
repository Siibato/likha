import 'package:flutter/material.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';

enum AssignmentStatus {
  open,
  pastDue,
  submitted,
  graded,
}

class AssignmentListCard extends StatelessWidget {
  final Assignment assignment;
  final AssignmentStatus status;
  final VoidCallback onTap;

  const AssignmentListCard({
    super.key,
    required this.assignment,
    required this.status,
    required this.onTap,
  });

  String _statusLabel(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.open:
        return 'Open';
      case AssignmentStatus.pastDue:
        return 'Past Due';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
    }
  }

  IconData _statusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.open:
        return Icons.assignment_outlined;
      case AssignmentStatus.pastDue:
        return Icons.warning_amber_rounded;
      case AssignmentStatus.submitted:
        return Icons.check_circle_outline_rounded;
      case AssignmentStatus.graded:
        return Icons.grading_rounded;
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

  String _submissionTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Text';
      case 'file':
        return 'File';
      case 'text_or_file':
        return 'Text/File';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              const SizedBox(height: 16),
              _buildInfoRow(),
              const SizedBox(height: 12),
              _buildDueDate(),
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
            assignment.title,
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

  Widget _buildInfoRow() {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.star_outline_rounded,
          label: '${assignment.totalPoints} pts',
        ),
        const SizedBox(width: 16),
        _InfoChip(
          icon: Icons.upload_file_rounded,
          label: _submissionTypeLabel(assignment.submissionType),
        ),
      ],
    );
  }

  Widget _buildDueDate() {
    return Row(
      children: [
        const Icon(
          Icons.event_rounded,
          size: 13,
          color: Color(0xFF999999),
        ),
        const SizedBox(width: 6),
        const Text(
          'Due: ',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _formatDateTime(assignment.dueAt),
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