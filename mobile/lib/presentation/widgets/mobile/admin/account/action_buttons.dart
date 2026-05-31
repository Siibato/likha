import 'package:flutter/material.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';

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
          StyledButton(
            text: 'Lock Account',
            icon: Icons.lock_outline_rounded,
            variant: StyledButtonVariant.destructive,
            isLoading: isLoading,
            onPressed: onLock,
            fullWidth: false,
          ),
        if (user.accountStatus == 'locked')
          StyledButton(
            text: 'Unlock Account',
            icon: Icons.lock_open_rounded,
            variant: StyledButtonVariant.primary,
            isLoading: isLoading,
            onPressed: onUnlock,
            fullWidth: false,
          ),
        StyledButton(
          text: 'Reset Password',
          icon: Icons.refresh_rounded,
          variant: StyledButtonVariant.outlined,
          isLoading: isLoading,
          onPressed: onResetPassword,
          fullWidth: false,
        ),
      ],
    );
  }
}
