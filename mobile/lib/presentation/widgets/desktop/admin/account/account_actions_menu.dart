import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';

class AccountActionsMenu extends StatelessWidget {
  final User user;
  final void Function(User user, bool locked)? onLock;
  final ValueChanged<User>? onResetPassword;
  final ValueChanged<User>? onDelete;

  const AccountActionsMenu({
    super.key,
    required this.user,
    this.onLock,
    this.onResetPassword,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = user.accountStatus == 'locked';

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: AppColors.backgroundSecondary,
        splashColor: AppColors.backgroundSecondary,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: AppColors.foregroundSecondary,
        ),
        tooltip: 'Actions',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        elevation: 8,
        offset: const Offset(0, 8),
        color: Colors.white,
        onSelected: (value) {
          switch (value) {
            case 'lock':
              onLock?.call(user, !isLocked);
              break;
            case 'reset':
              onResetPassword?.call(user);
              break;
            case 'delete':
              onDelete?.call(user);
              break;
          }
        },
        itemBuilder: (context) => [
          if (onLock != null)
            PopupMenuItem(
              value: 'lock',
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: _MenuItem(
                icon: isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                label: isLocked ? 'Unlock' : 'Lock',
                isDestructive: false,
              ),
            ),
          if (onResetPassword != null)
            PopupMenuItem(
              value: 'reset',
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: _MenuItem(
                icon: Icons.refresh_rounded,
                label: 'Reset Password',
                isDestructive: false,
              ),
            ),
          if (onDelete != null) ...[
            const PopupMenuDivider(height: 8),
            PopupMenuItem(
              value: 'delete',
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: _MenuItem(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                isDestructive: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDestructive
              ? AppColors.semanticErrorDark
              : AppColors.foregroundTertiary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDestructive
                ? AppColors.semanticErrorDark
                : AppColors.foregroundDark,
          ),
        ),
      ],
    );
  }
}
