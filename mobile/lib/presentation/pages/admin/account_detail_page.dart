import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/admin/widgets/info_card.dart';
import 'package:likha/presentation/pages/admin/widgets/action_buttons.dart';
import 'package:likha/presentation/pages/admin/widgets/activity_log_list.dart';
import 'package:likha/presentation/pages/admin/widgets/edit_dialog.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

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
      ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final User user = adminState.accounts
        .cast<User>()
        .firstWhere((a) => a.id == widget.user.id, orElse: () => widget.user);

    ref.listen<AdminState>(adminProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        ref.read(adminProvider.notifier).clearMessages();
        ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
      }
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
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
            color: Color(0xFF404040),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            color: Color(0xFF202020),
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
              onEditUsername: () => _showEditDialog(
                context,
                title: 'Edit Username',
                currentValue: user.username,
                onSave: (value) {
                  ref.read(adminProvider.notifier).updateAccount(
                        userId: user.id,
                        username: value,
                      );
                },
              ),
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
              onEditRole: () => _showRoleDialog(context, user),
            ),
            const SizedBox(height: 24),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            ActionButtons(
              user: user,
              isLoading: adminState.isLoading,
              onLock: () => ref
                  .read(adminProvider.notifier)
                  .lockAccount(user.id, true),
              onUnlock: () => ref
                  .read(adminProvider.notifier)
                  .lockAccount(user.id, false),
              onResetPassword: () => _confirmReset(context, user),
            ),
            const SizedBox(height: 32),
            const Text(
              'Activity Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF202020),
          ),
        ),
        content: Text(
          'This will clear ${user.fullName}\'s password and set the account back to pending activation. Continue?',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF404040),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF999999),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminProvider.notifier).resetAccount(user.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC3545),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, User user) {
    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Change Role',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF202020),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Changing a user\'s role affects their access to features. This change will sync when connected.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['student', 'teacher', 'admin']
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF999999),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: selectedRole == user.role
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      ref.read(adminProvider.notifier).updateAccount(
                            userId: user.id,
                            role: selectedRole,
                          );
                    },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF007AFF),
              ),
              child: const Text(
                'Change',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}