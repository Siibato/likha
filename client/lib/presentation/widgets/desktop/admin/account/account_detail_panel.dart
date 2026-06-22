import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'account_status_badge.dart';
import 'package:likha/presentation/widgets/desktop/admin/shared/date_utils.dart';
import 'package:likha/presentation/widgets/shared/cards/base_action_card.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

class AccountDetailPanel extends StatelessWidget {
  final User user;
  final bool isLoading;
  final VoidCallback onEditFirstName;
  final VoidCallback onEditLastName;
  final VoidCallback onLock;
  final VoidCallback onUnlock;
  final VoidCallback onResetPassword;

  const AccountDetailPanel({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onEditFirstName,
    required this.onEditLastName,
    required this.onLock,
    required this.onUnlock,
    required this.onResetPassword,
  });

  
  
  @override
  Widget build(BuildContext context) {
    return BaseActionCard(
      title: 'Account Information',
      subtitle: user.username,
      icon: const Icon(Icons.person_outline_rounded),
      actions: [
        if (user.accountStatus != 'locked')
          StyledButton(
            text: 'Lock Account',
            icon: Icons.lock_outline_rounded,
            variant: StyledButtonVariant.outlined,
            isLoading: isLoading,
            onPressed: onLock,
            fullWidth: false,
          ),
        if (user.accountStatus == 'locked')
          StyledButton(
            text: 'Unlock Account',
            icon: Icons.lock_open_rounded,
            variant: StyledButtonVariant.outlined,
            isLoading: isLoading,
            onPressed: onUnlock,
            fullWidth: false,
          ),
        const SizedBox(width: 8),
        StyledButton(
          text: 'Reset Password',
          icon: Icons.refresh_rounded,
          variant: StyledButtonVariant.outlined,
          isLoading: isLoading,
          onPressed: onResetPassword,
          fullWidth: false,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _EditableRow(
            label: 'First Name',
            value: user.firstName,
            onEdit: isLoading ? null : onEditFirstName,
          ),
          const Divider(height: 24, color: AppColors.borderLight),
          _EditableRow(
            label: 'Last Name',
            value: user.lastName,
            onEdit: isLoading ? null : onEditLastName,
          ),
          const Divider(height: 24, color: AppColors.borderLight),
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

