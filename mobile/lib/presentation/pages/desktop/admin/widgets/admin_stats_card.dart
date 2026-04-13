import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A reusable statistics card widget for admin dashboard
/// with consistent styling and layout for displaying metrics.
class AdminStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final bool isLoading;

  const AdminStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.isLoading = false,
  });

  /// Creates a stats card for total accounts
  factory AdminStatsCard.totalAccounts({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Total Accounts',
      value: count.toString(),
      icon: Icons.people_outline_rounded,
      iconColor: const Color(0xFF007BFF),
      backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for active accounts
  factory AdminStatsCard.activeAccounts({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Active Accounts',
      value: count.toString(),
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF28A745),
      backgroundColor: const Color(0xFF28A745).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for total classes
  factory AdminStatsCard.totalClasses({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Total Classes',
      value: count.toString(),
      icon: Icons.school_outlined,
      iconColor: const Color(0xFF6F42C1),
      backgroundColor: const Color(0xFF6F42C1).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for pending activations
  factory AdminStatsCard.pendingActivations({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Pending Activations',
      value: count.toString(),
      icon: Icons.pending_outlined,
      iconColor: const Color(0xFFFFC107),
      backgroundColor: const Color(0xFFFFC107).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for locked accounts
  factory AdminStatsCard.lockedAccounts({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Locked Accounts',
      value: count.toString(),
      icon: Icons.lock_outline_rounded,
      iconColor: const Color(0xFFDC3545),
      backgroundColor: const Color(0xFFDC3545).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for total students
  factory AdminStatsCard.totalStudents({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Total Students',
      value: count.toString(),
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF17A2B8),
      backgroundColor: const Color(0xFF17A2B8).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for total teachers
  factory AdminStatsCard.totalTeachers({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Total Teachers',
      value: count.toString(),
      icon: Icons.co_present_outlined,
      iconColor: const Color(0xFFFD7E14),
      backgroundColor: const Color(0xFFFD7E14).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  /// Creates a stats card for recent activity
  factory AdminStatsCard.recentActivity({
    required int count,
    VoidCallback? onTap,
    double? width,
    bool isLoading = false,
  }) {
    return AdminStatsCard(
      title: 'Recent Activity',
      value: count.toString(),
      subtitle: 'Last 24 hours',
      icon: Icons.work_outline,
      iconColor: const Color(0xFF20C997),
      backgroundColor: const Color(0xFF20C997).withOpacity(0.1),
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.foregroundPrimary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: iconColor ?? AppColors.foregroundPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            icon,
                            size: 24,
                            color: iconColor ?? AppColors.foregroundPrimary,
                          ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.foregroundTertiary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of admin stats cards with responsive layout
class AdminStatsRow extends StatelessWidget {
  final List<AdminStatsCard> cards;
  final double spacing;
  final double runSpacing;

  const AdminStatsRow({
    super.key,
    required this.cards,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: cards.map((card) {
        // Make cards responsive - take full width on small screens, fixed width on larger screens
        return SizedBox(
          width: 280,
          child: card,
        );
      }).toList(),
    );
  }
}
