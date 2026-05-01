import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'account_actions_menu.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/base_data_table.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/status_badge.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/empty_state.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/date_utils.dart';

class AccountDataTable extends StatelessWidget {
  final List<User> accounts;
  final ValueChanged<User> onTap;
  final void Function(User user, bool locked)? onLock;
  final ValueChanged<User>? onResetPassword;
  final ValueChanged<User>? onDelete;
  final int rowsPerPage;

  const AccountDataTable({
    super.key,
    required this.accounts,
    required this.onTap,
    this.onLock,
    this.onResetPassword,
    this.onDelete,
    this.rowsPerPage = 20,
  });

  Widget _buildAccountStatusBadge(String status) {
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'activated':
        statusColor = AppColors.semanticSuccessAlt;
        statusLabel = 'Active';
        break;
      case 'pending_activation':
        statusColor = AppColors.accentAmber;
        statusLabel = 'Pending';
        break;
      case 'locked':
        statusColor = AppColors.semanticErrorDark;
        statusLabel = 'Locked';
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
      activeBackgroundColor: statusColor.withOpacity(0.12),
      inactiveBackgroundColor: statusColor.withOpacity(0.12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActions = onLock != null ||
        onResetPassword != null ||
        onDelete != null;

    return BaseDataTable<User>(
      items: accounts,
      columns: [
        DataColumn(
          label: const Text('Name', style: dataTableHeaderStyle),
          onSort: (_, __) {},
        ),
        const DataColumn(
          label: Text('Username', style: dataTableHeaderStyle),
        ),
        DataColumn(
          label: const Text('Role', style: dataTableHeaderStyle),
          onSort: (_, __) {},
        ),
        DataColumn(
          label: const Text('Status', style: dataTableHeaderStyle),
          onSort: (_, __) {},
        ),
        const DataColumn(
          label: Text('Created', style: dataTableHeaderStyle),
        ),
        if (hasActions)
          const DataColumn(
            label: Text('', style: dataTableHeaderStyle),
          ),
      ],
      rowBuilder: (context, user, index) {
        return [
          // Name column with avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundDark,
                ),
              ),
            ],
          ),
          // Username column
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
          // Role column
          Text(
            user.role[0].toUpperCase() + user.role.substring(1),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
          // Status column
          _buildAccountStatusBadge(user.accountStatus),
          // Created date column
          Text(
            DesktopDateUtils.formatDateIso(user.createdAt),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundTertiary,
            ),
          ),
          // Actions column
          if (hasActions)
            AccountActionsMenu(
              user: user,
              onLock: onLock,
              onResetPassword: onResetPassword,
              onDelete: onDelete,
            ),
        ];
      },
      onTap: onTap,
      rowsPerPage: rowsPerPage,
      emptyState: EmptyState.generic(
        title: 'No accounts found',
        subtitle: 'No accounts match your search criteria',
        icon: Icons.person_outline_rounded,
      ),
    );
  }
}
