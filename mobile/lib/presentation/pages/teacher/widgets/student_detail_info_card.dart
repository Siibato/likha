import 'package:flutter/material.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';

class StudentDetailInfoCard extends StatelessWidget {
  final User student;
  final String classTitle;

  const StudentDetailInfoCard({
    super.key,
    required this.student,
    required this.classTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with initial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Username',
                  value: '@${student.username}',
                ),
                const Divider(
                  height: 16,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                _InfoRow(
                  label: 'Full Name',
                  value: student.fullName,
                ),
                const Divider(
                  height: 16,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                _InfoRow(
                  label: 'Class',
                  value: classTitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202020),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
