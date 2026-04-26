import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'account_status_badge.dart';
import 'package:likha/presentation/pages/desktop/admin/utils/date_utils.dart';

class AccountDetailPanel extends StatelessWidget {
  final User user;
  final bool isLoading;
  final VoidCallback onEditFullName;
  final VoidCallback? onEditRole;
  final VoidCallback onLock;
  final VoidCallback onUnlock;
  final VoidCallback onResetPassword;

  const AccountDetailPanel({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onEditFullName,
    this.onEditRole,
    required this.onLock,
    required this.onUnlock,
    required this.onResetPassword,
  });

  
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                  ),
                ),
                const SizedBox(height: 20),
                _InfoRow(label: 'Username', value: user.username),
                const Divider(height: 24, color: AppColors.borderLight),
                _EditableRow(
                  label: 'Full Name',
                  value: user.fullName,
                  onEdit: isLoading ? null : onEditFullName,
                ),
                const Divider(height: 24, color: AppColors.borderLight),
                if (onEditRole != null)
                  _EditableRow(
                    label: 'Role',
                    value: user.role[0].toUpperCase() + user.role.substring(1),
                    onEdit: isLoading ? null : onEditRole,
                  )
                else
                  _InfoRow(
                    label: 'Role',
                    value: user.role[0].toUpperCase() + user.role.substring(1),
                  ),
                const Divider(height: 24, color: AppColors.borderLight),
                Row(
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text('Status', style: _labelStyle),
                    ),
                    const SizedBox(width: 12),
                    AccountStatusBadge(status: user.accountStatus),
                  ],
                ),
                const Divider(height: 24, color: AppColors.borderLight),
                _InfoRow(label: 'Created', value: DesktopDateUtils.formatDate(user.createdAt)),
                if (user.activatedAt != null) ...[
                  const Divider(height: 24, color: AppColors.borderLight),
                  _InfoRow(
                    label: 'Activated',
                    value: DesktopDateUtils.formatDate(user.activatedAt!),
                  ),
                ],
              ],
            ),
          ),

          // Actions section
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (user.accountStatus != 'locked')
                      _ActionChip(
                        icon: Icons.lock_outline_rounded,
                        label: 'Lock Account',
                        color: AppColors.semanticErrorDark,
                        onTap: isLoading ? null : onLock,
                      ),
                    if (user.accountStatus == 'locked')
                      _ActionChip(
                        icon: Icons.lock_open_rounded,
                        label: 'Unlock Account',
                        color: AppColors.semanticSuccessAlt,
                        onTap: isLoading ? null : onUnlock,
                      ),
                    _ActionChip(
                      icon: Icons.refresh_rounded,
                      label: 'Reset Password',
                      color: AppColors.accentAmber,
                      onTap: isLoading ? null : onResetPassword,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.foregroundTertiary,
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AccountDetailPanel._labelStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _EditableRow({
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AccountDetailPanel._labelStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.foregroundSecondary,
            onPressed: onEdit,
            splashRadius: 20,
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Material(
      color: isDisabled
          ? AppColors.backgroundDisabled
          : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDisabled ? AppColors.foregroundTertiary : AppColors.foregroundPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? AppColors.foregroundTertiary : AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
