import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';

class TeacherStatsRow extends StatelessWidget {
  final List<ClassEntity> classes;

  const TeacherStatsRow({super.key, required this.classes});

  @override
  Widget build(BuildContext context) {
    final totalStudents =
        classes.fold<int>(0, (sum, c) => sum + c.studentCount);
    final advisoryCount = classes.where((c) => c.isAdvisory).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF5C6BC0),
          count: classes.length,
          label: 'Total Classes',
        ),
        _StatCard(
          icon: Icons.people_rounded,
          iconColor: const Color(0xFF26A69A),
          count: totalStudents,
          label: 'Total Students',
        ),
        _StatCard(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF4CAF50),
          count: advisoryCount,
          label: 'Advisory Classes',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
