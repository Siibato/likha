import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/edit_dialog.dart';
import 'package:likha/presentation/widgets/desktop/admin/account/account_detail_panel.dart';
import 'package:likha/presentation/widgets/desktop/admin/account/activity_log_table.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/cards/learner_details_card.dart';
import 'package:likha/presentation/widgets/shared/cards/teacher_details_card.dart';
import 'package:likha/presentation/widgets/shared/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class AccountDetailPage extends ConsumerStatefulWidget {
  final User user;

  const AccountDetailPage({super.key, required this.user});

  @override
  ConsumerState<AccountDetailPage> createState() =>
      _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
      ref.read(adminProvider.notifier).loadAccountDetails(widget.user.id);
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
        ref.read(adminProvider.notifier).clearMessages();
        ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
      }
      if (next.error != null && prev?.error != next.error) {
        ref.read(adminProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: user.fullName,
        subtitle: '@${user.username}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Account info + actions + details
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccountDetailPanel(
                      user: user,
                      isLoading: adminState.isLoading,
                      onEditFirstName: () => _showEditDialog(
                        context,
                        title: 'Edit First Name',
                        currentValue: user.firstName,
                        onSave: (value) => ref.read(adminProvider.notifier).updateAccount(
                          userId: user.id,
                          firstName: value.trim(),
                        ),
                      ),
                      onEditLastName: () => _showEditDialog(
                        context,
                        title: 'Edit Last Name',
                        currentValue: user.lastName,
                        onSave: (value) => ref.read(adminProvider.notifier).updateAccount(
                          userId: user.id,
                          lastName: value.trim(),
                        ),
                      ),
                      onLock: () => _showLockDialog(context, user),
                      onUnlock: () => ref
                          .read(adminProvider.notifier)
                          .lockAccount(user.id, false),
                      onResetPassword: () => _confirmReset(context, user),
                    ),
                    const SizedBox(height: 24),
                    if (user.role == 'student')
                      LearnerDetailsCard(
                        details: adminState.learnerDetails,
                        isLoading: adminState.isLoading,
                        onSave: (data) => ref.read(adminProvider.notifier).updateAccountDetails(
                          userId: user.id,
                          learnerDetails: data,
                        ),
                      )
                    else if (user.role == 'teacher')
                      TeacherDetailsCard(
                        details: adminState.teacherDetails,
                        isLoading: adminState.isLoading,
                        onSave: (data) => ref.read(adminProvider.notifier).updateAccountDetails(
                          userId: user.id,
                          teacherDetails: data,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right: Activity log
            Expanded(
              flex: 1,
              child: ActivityLogTable(
                logs: adminState.activityLogs,
                isLoading: adminState.isLoading,
              ),
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
      body:
          "This will clear ${user.fullName}'s password and set the account back to pending activation. Continue?",
      confirmLabel: 'Reset',
      onConfirm: () =>
          ref.read(adminProvider.notifier).resetAccount(user.id),
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
            user.id,
            true,
            reason:
                controller.text.isEmpty ? null : controller.text,
          ),
    );
  }
}
