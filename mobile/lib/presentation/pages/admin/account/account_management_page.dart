import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/admin/account/account_detail_page.dart';
import 'package:likha/presentation/widgets/mobile/admin/account/account_tile.dart';
import 'package:likha/presentation/widgets/shared/search/app_search_bar.dart';
import 'package:likha/presentation/widgets/shared/feedback/content_state_builder.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    final filteredAccounts = adminState.accounts.where((user) {
      if (user.isAdmin) return false;
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
          Expanded(
            child: ContentStateBuilder(
              isLoading: adminState.isLoading && adminState.accounts.isEmpty,
              error: adminState.error,
              isEmpty: filteredAccounts.isEmpty,
              onRetry: () => ref.read(adminProvider.notifier).loadAccounts(),
              onRefresh: () => ref.read(adminProvider.notifier).loadAccounts(),
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
                        .read(adminProvider.notifier)
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