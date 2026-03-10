import 'package:flutter/material.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card_sm.dart';

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
            color: Color(0xFFCCCCCC),
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
            ? const Color(0xFFE0E0E0)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        assignment.isPublished
            ? Icons.assignment_turned_in_rounded
            : Icons.assignment_outlined,
        color: assignment.isPublished
            ? const Color(0xFF2B2B2B)
            : const Color(0xFF999999),
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
            color: Color(0xFF202020),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${assignment.totalPoints} pts • ${assignment.submissionCount} submissions • ${assignment.gradedCount} graded',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}