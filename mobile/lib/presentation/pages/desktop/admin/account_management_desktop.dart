import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/desktop/admin/account_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/create_account_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/widgets/account_data_table.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';

class AccountManagementDesktop extends ConsumerStatefulWidget {
  const AccountManagementDesktop({super.key});

  @override
  ConsumerState<AccountManagementDesktop> createState() =>
      _AccountManagementDesktopState();
}

class _AccountManagementDesktopState
    extends ConsumerState<AccountManagementDesktop> {
  String _searchQuery = '';
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAccounts();
    });
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
          // Search + filters
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search accounts...',
                      hintStyle: TextStyle(
                        color: AppColors.foregroundTertiary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.foregroundTertiary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Role filter chips
              _FilterChip(
                label: 'All',
                isSelected: _selectedRole == null,
                onTap: () => setState(() => _selectedRole = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Teachers',
                isSelected: _selectedRole == 'teacher',
                onTap: () => setState(() => _selectedRole = 'teacher'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Students',
                isSelected: _selectedRole == 'student',
                onTap: () => setState(() => _selectedRole = 'student'),
              ),
            ],
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.foregroundDark : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected ? AppColors.foregroundDark : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.foregroundSecondary,
            ),
          ),
        ),
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
              color: Color(0xFF666666),
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
                color: Color(0xFFCCCCCC),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
              color: Color(0xFF202020),
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
          color: const Color(0xFFDC3545).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFDC3545).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_rounded,
                size: 18, color: Color(0xFFDC3545)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This will permanently delete "${widget.userName}". This action cannot be undone.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFDC3545),
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
              color: Color(0xFF666666),
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
                color: Color(0xFFCCCCCC),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFDC3545), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF202020),
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
