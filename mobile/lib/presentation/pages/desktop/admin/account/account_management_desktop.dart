import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/desktop/admin/account/account_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/account/create_account_desktop.dart';
import 'package:likha/presentation/widgets/desktop/admin/account/account_data_table.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/search/search_filter_bar.dart';

class AccountManagementDesktop extends ConsumerStatefulWidget {
  const AccountManagementDesktop({super.key});

  @override
  ConsumerState<AccountManagementDesktop> createState() =>
      _AccountManagementDesktopState();
}

class _AccountManagementDesktopState
    extends ConsumerState<AccountManagementDesktop> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAccounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleLock(User user, bool locked) {
    if (locked) {
      // Show reason dialog for locking
      showDialog(
        context: context,
        builder: (ctx) => _LockReasonDialog(
          userName: user.fullName,
          onConfirm: (reason) {
            Navigator.pop(ctx);
            ref.read(adminProvider.notifier).lockAccount(
                  user.id,
                  true,
                  reason: reason,
                );
          },
        ),
      );
    } else {
      // Unlock directly
      ref.read(adminProvider.notifier).lockAccount(user.id, false);
    }
  }

  void _handleResetPassword(User user) {
    showDialog(
      context: context,
      builder: (ctx) => StyledDialog(
        title: 'Reset Password',
        content: Text(
          'This will clear the password for "${user.fullName}" and set the account back to pending activation.',
          style: const TextStyle(fontSize: 14, color: AppColors.foregroundSecondary),
        ),
        actions: [
          StyledDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          StyledDialogAction(
            label: 'Reset',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminProvider.notifier).resetAccount(user.id);
            },
          ),
        ],
      ),
    );
  }

  void _handleDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteAccountDialog(
        userName: user.fullName,
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(adminProvider.notifier).deleteAccount(user.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    final filteredAccounts = adminState.accounts.where((user) {
      if (user.isAdmin) return false;
      if (_selectedRole != null && user.role != _selectedRole) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return user.username.toLowerCase().contains(q) ||
          user.fullName.toLowerCase().contains(q) ||
          user.role.toLowerCase().contains(q);
    }).toList();

    return DesktopPageScaffold(
      title: 'Account Management',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAccountDesktop()),
          ).then((_) => ref.read(adminProvider.notifier).loadAccounts()),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Account'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar.accounts(
            controller: _searchController,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            selectedRole: _selectedRole,
            onRoleChanged: (role) => setState(() => _selectedRole = role),
          ),
          const SizedBox(height: 20),

          // Data table
          if (adminState.isLoading && adminState.accounts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            AccountDataTable(
              accounts: filteredAccounts,
              onTap: (user) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountDetailDesktop(user: user),
                ),
              ).then((_) => ref.read(adminProvider.notifier).loadAccounts()),
              onLock: _handleLock,
              onResetPassword: _handleResetPassword,
              onDelete: _handleDelete,
            ),
        ],
      ),
    );
  }
}

class _LockReasonDialog extends StatefulWidget {
  final String userName;
  final ValueChanged<String?> onConfirm;

  const _LockReasonDialog({
    required this.userName,
    required this.onConfirm,
  });

  @override
  State<_LockReasonDialog> createState() => _LockReasonDialogState();
}

class _LockReasonDialogState extends State<_LockReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Lock Account',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lock the account for "${widget.userName}"?',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reason (optional):',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter reason...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.foregroundPrimary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundDark,
            ),
          ),
        ],
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Lock Account',
          isPrimary: true,
          isDestructive: true,
          onPressed: () {
            final reason = _controller.text.trim();
            widget.onConfirm(reason.isEmpty ? null : reason);
          },
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final String userName;
  final VoidCallback onConfirm;

  const _DeleteAccountDialog({
    required this.userName,
    required this.onConfirm,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final match = _controller.text.trim() == 'DELETE';
      if (match != _canConfirm) setState(() => _canConfirm = match);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Delete Account',
      warningBox: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.semanticErrorDark.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.semanticErrorDark.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_rounded,
                size: 18, color: AppColors.semanticErrorDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This will permanently delete "${widget.userName}". This action cannot be undone.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.semanticErrorDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type DELETE to confirm:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.semanticErrorDark, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foregroundDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Delete Account',
          isPrimary: true,
          isDestructive: true,
          onPressed: _canConfirm ? widget.onConfirm : () {},
        ),
      ],
    );
  }
}
