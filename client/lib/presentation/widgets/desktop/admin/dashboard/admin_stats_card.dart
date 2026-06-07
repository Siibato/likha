import 'package:flutter/material.dart';
import 'package:likha/presentation/widgets/shared/cards/base_stats_card.dart';

/// A reusable statistics card widget for admin dashboard
/// with consistent styling and layout for displaying metrics.
/// 
/// Now extends BaseStatsCard for consistent design and reduced code duplication.
class AdminStatsCard extends BaseStatsCard {
  const AdminStatsCard({
    super.key,
    required super.title,
    required super.value,
    super.subtitle,
    required super.icon,
    super.iconColor,
    super.backgroundColor,
    super.onTap,
    super.width,
    super.isLoading = false,
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
      onTap: onTap,
      width: width,
      isLoading: isLoading,
    );
  }
}

/// A row of admin stats cards with responsive layout
/// 
/// Now extends BaseStatsRow for consistent design and reduced code duplication.
class AdminStatsRow extends BaseStatsRow {
  const AdminStatsRow({
    super.key,
    required super.cards,
    super.spacing = 16,
    super.runSpacing = 16,
  });
}
