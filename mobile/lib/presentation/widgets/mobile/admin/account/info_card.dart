import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';

class UserInfoCard extends StatelessWidget {
  final User user;
  final bool isLoading;
  final VoidCallback onEditFullName;
  final VoidCallback? onEditRole;

  const UserInfoCard({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onEditFullName,
    this.onEditRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Username', value: user.username),
            const Divider(height: 24, color: AppColors.borderLight),
            _EditableInfoRow(
              label: 'Full Name',
              value: user.fullName,
              onEdit: isLoading ? null : onEditFullName,
            ),
            const Divider(height: 24, color: AppColors.borderLight),
            if (onEditRole != null)
              _EditableInfoRow(
                label: 'Role',
                value: user.role,
                onEdit: isLoading ? null : onEditRole,
              )
            else
              _InfoRow(label: 'Role', value: user.role),
            const Divider(height: 24, color: AppColors.borderLight),
            _InfoRow(label: 'Status', value: user.accountStatus),
            const Divider(height: 24, color: AppColors.borderLight),
            _InfoRow(
              label: 'Created',
              value: _formatDate(user.createdAt),
            ),
            if (user.activatedAt != null) ...[
              const Divider(height: 24, color: AppColors.borderLight),
              _InfoRow(
                label: 'Activated',
                value: _formatDate(user.activatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.toString().split('.')[0];
  }
}

class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _EditableInfoRow({
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundTertiary,
            ),
          ),
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
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.foregroundDark,
              ),
            ),
          ),
      ],
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
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundTertiary,
            ),
          ),
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