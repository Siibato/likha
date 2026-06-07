import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/status_badge.dart';

/// A specialized status badge widget for account statuses
/// with predefined colors and labels for common account states.
class AccountStatusBadge extends StatelessWidget {
  final String status;

  const AccountStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'activated':
        statusColor = AppColors.accentCharcoal;
        statusLabel = 'Active';
        break;
      case 'pending_activation':
        statusColor = AppColors.accentAmberBorder;
        statusLabel = 'Pending';
        break;
      case 'locked':
        statusColor = AppColors.semanticErrorDark;
        statusLabel = 'Locked';
        break;
      case 'suspended':
        statusColor = AppColors.foregroundSecondary;
        statusLabel = 'Suspended';
        break;
      case 'deactivated':
        statusColor = AppColors.foregroundTertiary;
        statusLabel = 'Deactivated';
        break;
      default:
        statusColor = AppColors.foregroundTertiary;
        statusLabel = status;
    }

    return StatusBadge.custom(
      isActive: status == 'activated',
      activeText: statusLabel,
      inactiveText: statusLabel,
      activeColor: statusColor,
      inactiveColor: statusColor,
      activeBackgroundColor: statusColor.withValues(alpha: 0.12),
      inactiveBackgroundColor: statusColor.withValues(alpha: 0.12),
    );
  }

  /// Creates a badge for active status
  static Widget active({EdgeInsets? padding}) {
    return const AccountStatusBadge(status: 'activated');
  }

  /// Creates a badge for pending status
  static Widget pending({EdgeInsets? padding}) {
    return const AccountStatusBadge(status: 'pending_activation');
  }

  /// Creates a badge for locked status
  static Widget locked({EdgeInsets? padding}) {
    return const AccountStatusBadge(status: 'locked');
  }

  /// Creates a badge for suspended status
  static Widget suspended({EdgeInsets? padding}) {
    return const AccountStatusBadge(status: 'suspended');
  }

  /// Creates a badge for deactivated status
  static Widget deactivated({EdgeInsets? padding}) {
    return const AccountStatusBadge(status: 'deactivated');
  }

  /// Gets the color for a given status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'activated':
        return AppColors.accentCharcoal;
      case 'pending_activation':
        return AppColors.accentAmberBorder;
      case 'locked':
        return AppColors.semanticErrorDark;
      case 'suspended':
        return AppColors.foregroundSecondary;
      case 'deactivated':
        return AppColors.foregroundTertiary;
      default:
        return AppColors.foregroundTertiary;
    }
  }

  /// Gets the label for a given status
  static String getStatusLabel(String status) {
    switch (status) {
      case 'activated':
        return 'Active';
      case 'pending_activation':
        return 'Pending';
      case 'locked':
        return 'Locked';
      case 'suspended':
        return 'Suspended';
      case 'deactivated':
        return 'Deactivated';
      default:
        return status;
    }
  }

  /// Checks if a status is considered active
  static bool isActive(String status) {
    return status == 'activated';
  }

  /// Checks if a status is considered inactive
  static bool isInactive(String status) {
    return ['locked', 'suspended', 'deactivated'].contains(status);
  }

  /// Checks if a status is pending
  static bool isPending(String status) {
    return status == 'pending_activation';
  }
}
