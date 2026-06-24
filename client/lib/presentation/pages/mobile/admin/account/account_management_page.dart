import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/mobile/admin/account/account_detail_page.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/account_tile.dart';
import 'package:likha/presentation/widgets/shared/search/app_search_bar.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';
import 'package:likha/presentation/widgets/shared/import/bulk_import_dialog.dart';
import 'package:likha/presentation/widgets/shared/import/history_import_dialog.dart';
import 'package:likha/presentation/providers/admin/admin_provider.dart';

class AccountManagementPage extends ConsumerStatefulWidget {
  const AccountManagementPage({super.key});

  @override
  ConsumerState<AccountManagementPage> createState() =>
      _AccountManagementPageState();
}

class _AccountManagementPageState
    extends ConsumerState<AccountManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountManagementProvider.notifier).loadAccounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountMgmtState = ref.watch(accountManagementProvider);

    final filteredAccounts = accountMgmtState.accounts.where((user) {
      if (user.isAdmin) return false;
      if (_selectedRole != null && user.role != _selectedRole) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return user.username.toLowerCase().contains(q) ||
          user.fullName.toLowerCase().contains(q) ||
          user.role.toLowerCase().contains(q);
    }).toList();

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
        title: const Text(
          'Account Management',
          style: TextStyle(
            color: AppColors.foregroundDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'bulk') {
                showDialog(
                  context: context,
                  builder: (_) => BulkImportDialog(
                    onSuccess: () => ref.read(accountManagementProvider.notifier).loadAccounts(),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => HistoryImportDialog(
                    type: value,
                    title: {
                      'school_history': 'Import School History',
                      'subjects': 'Import Previous Subjects',
                      'attendance': 'Import Attendance',
                    }[value]!,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk',
                child: Row(children: [
                  Icon(Icons.upload_file_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Bulk Import Students'),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'school_history',
                child: Row(children: [
                  Icon(Icons.history_edu_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Import School History'),
                ]),
              ),
              const PopupMenuItem(
                value: 'subjects',
                child: Row(children: [
                  Icon(Icons.menu_book_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Import Previous Subjects'),
                ]),
              ),
              const PopupMenuItem(
                value: 'attendance',
                child: Row(children: [
                  Icon(Icons.calendar_month_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Import Attendance'),
                ]),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.foregroundDark),
          ),
        ],
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hint: 'Search accounts...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _RoleFilterChip(
                  label: 'All',
                  selected: _selectedRole == null,
                  onTap: () => setState(() => _selectedRole = null),
                ),
                const SizedBox(width: 8),
                _RoleFilterChip(
                  label: 'Teacher',
                  selected: _selectedRole == 'teacher',
                  onTap: () => setState(() => _selectedRole = 'teacher'),
                ),
                const SizedBox(width: 8),
                _RoleFilterChip(
                  label: 'Student',
                  selected: _selectedRole == 'student',
                  onTap: () => setState(() => _selectedRole = 'student'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ContentStateBuilder(
              isLoading: accountMgmtState.isLoading && accountMgmtState.accounts.isEmpty,
              error: accountMgmtState.error,
              isEmpty: filteredAccounts.isEmpty,
              onRetry: () => ref.read(accountManagementProvider.notifier).loadAccounts(),
              onRefresh: () => ref.read(accountManagementProvider.notifier).loadAccounts(),
              emptyState: const Center(
                child: Text(
                  'No accounts found',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: filteredAccounts.length,
                itemBuilder: (context, index) {
                  final user = filteredAccounts[index];
                  return AccountTile(
                    user: user,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountDetailPage(user: user),
                      ),
                    ).then((_) => ref
                        .read(accountManagementProvider.notifier)
                        .loadAccounts()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentCharcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accentCharcoal : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.foregroundTertiary,
          ),
        ),
      ),
    );
  }
}