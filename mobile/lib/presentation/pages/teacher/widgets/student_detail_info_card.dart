import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
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
              color: AppColors.backgroundTertiary,
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
                  color: AppColors.foregroundPrimary,
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
                  color: AppColors.borderLight,
                ),
                _InfoRow(
                  label: 'Full Name',
                  value: student.fullName,
                ),
                const Divider(
                  height: 16,
                  thickness: 1,
                  color: AppColors.borderLight,
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
              color: AppColors.foregroundTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
