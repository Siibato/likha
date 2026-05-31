import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';

class AdminStatsRow extends StatelessWidget {
  final List<User> accounts;

  const AdminStatsRow({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final nonAdmin = accounts.where((u) => !u.isAdmin).toList();
    final total = nonAdmin.length;
    final active = nonAdmin.where((u) => u.isActivated).length;
    final locked = nonAdmin.where((u) => u.isLocked).length;
    final pending = nonAdmin.where((u) => u.isPendingActivation).length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          icon: Icons.people_rounded,
          iconColor: AppColors.foregroundPrimary,
          count: total,
          label: 'Total Users',
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.foregroundPrimary,
          count: active,
          label: 'Active',
        ),
        _StatCard(
          icon: Icons.lock_rounded,
          iconColor: AppColors.foregroundPrimary,
          count: locked,
          label: 'Locked',
        ),
        _StatCard(
          icon: Icons.pending_rounded,
          iconColor: AppColors.foregroundPrimary,
          count: pending,
          label: 'Pending',
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
