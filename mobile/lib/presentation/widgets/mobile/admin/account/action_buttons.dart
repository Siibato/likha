import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';

class ActionButtons extends StatelessWidget {
  final User user;
  final bool isLoading;
  final VoidCallback onLock;
  final VoidCallback onUnlock;
  final VoidCallback onResetPassword;

  const ActionButtons({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onLock,
    required this.onUnlock,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (user.accountStatus != 'locked')
          _ActionButton(
            icon: Icons.lock_outline_rounded,
            label: 'Lock Account',
            backgroundColor: AppColors.semanticErrorDark,
            onPressed: isLoading ? null : onLock,
          ),
        if (user.accountStatus == 'locked')
          _ActionButton(
            icon: Icons.lock_open_rounded,
            label: 'Unlock Account',
            backgroundColor: AppColors.semanticSuccessAlt,
            onPressed: isLoading ? null : onUnlock,
          ),
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Reset Password',
          backgroundColor: AppColors.accentAmber,
          onPressed: isLoading ? null : onResetPassword,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.borderLight
              : _getLightBackground(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDisabled
                ? AppColors.foregroundLight
                : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.backgroundDisabled
                : _getLightBackground(),
            borderRadius: BorderRadius.circular(13),
          ),
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

  Color _getLightBackground() {
    // Create a light tinted background while maintaining semantic color
    return backgroundColor.withValues(alpha: 0.12);
  }
}