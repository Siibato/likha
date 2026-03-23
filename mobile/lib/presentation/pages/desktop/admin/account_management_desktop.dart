import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/admin/account_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/create_account_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/widgets/account_data_table.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

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
