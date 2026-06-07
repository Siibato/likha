import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/info_card.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/action_buttons.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/activity_log_list.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/edit_dialog.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';

class AccountDetailPage extends ConsumerStatefulWidget {
  final User user;

  const AccountDetailPage({super.key, required this.user});

  @override
  ConsumerState<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load activity logs without clearing first to avoid losing data during navigation
      ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final authState = ref.watch(authProvider);
    final User user = adminState.accounts
        .cast<User>()
        .firstWhere((a) => a.id == widget.user.id, orElse: () => widget.user);
    final currentUserId = authState.user?.id;

    ref.listen<AdminState>(adminProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ref.read(adminProvider.notifier).clearMessages();
        ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
      }
      if (next.error != null && prev?.error != next.error) {
        ref.read(adminProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.foregroundDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            color: AppColors.foregroundDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoCard(
              user: user,
              isLoading: adminState.isLoading,
              onEditFullName: () => _showEditDialog(
                context,
                title: 'Edit Full Name',
                currentValue: user.fullName,
                onSave: (value) {
                  ref.read(adminProvider.notifier).updateAccount(
                        userId: user.id,
                        fullName: value,
                      );
                },
              ),
              onEditRole: currentUserId != user.id ? () => _showRoleDialog(context, user) : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            ActionButtons(
              user: user,
              isLoading: adminState.isLoading,
              onLock: () => _showLockDialog(context, user),
              onUnlock: () => ref
                  .read(adminProvider.notifier)
                  .lockAccount(user.id, false),
              onResetPassword: () => _confirmReset(context, user),
            ),
            const SizedBox(height: 32),
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            ActivityLogList(
              logs: adminState.activityLogs,
              isLoading: adminState.isLoading,
            ),
            const SizedBox(height: 32),
            const Text(
              'Activity Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            ActivityLogList(
              logs: adminState.activityLogs,
              isLoading: adminState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String currentValue,
    required void Function(String) onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => EditDialog(
        title: title,
        currentValue: currentValue,
        onSave: onSave,
      ),
    );
  }

  void _confirmReset(BuildContext context, User user) {
    AppDialogs.showDestructive(
      context: context,
      title: 'Reset Password',
      body: "This will clear ${user.fullName}'s password and set the account back to pending activation. Continue?",
      confirmLabel: 'Reset',
      onConfirm: () => ref.read(adminProvider.notifier).resetAccount(user.id),
    );
  }

  void _showRoleDialog(BuildContext context, User user) {
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => StyledDialog(
          title: 'Change Role',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Changing a user's role affects their access to features. This change will sync when connected.",
                style: TextStyle(fontSize: 14, color: AppColors.foregroundSecondary),
              ),
              const SizedBox(height: 16),
              StyledDropdown<String>(
                value: selectedRole,
                label: 'Role',
                icon: Icons.work_outline_rounded,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) { if (v != null) setDialogState(() => selectedRole = v); },
              ),
            ],
          ),
          actions: [
            StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
            StyledDialogAction(
              label: 'Change',
              isPrimary: true,
              onPressed: selectedRole == user.role ? () {} : () {
                Navigator.pop(ctx);
                ref.read(adminProvider.notifier).updateAccount(userId: user.id, role: selectedRole);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLockDialog(BuildContext context, User user) {
    final controller = TextEditingController();
    AppDialogs.showInput(
      context: context,
      title: 'Lock Account',
      subtitle: 'This will prevent the user from accessing their account.',
      controller: controller,
      labelText: 'Reason (optional)',
      confirmLabel: 'Lock',
      onConfirm: () => ref.read(adminProvider.notifier).lockAccount(
        user.id, true, reason: controller.text.isEmpty ? null : controller.text,
      ),
    );
  }
}