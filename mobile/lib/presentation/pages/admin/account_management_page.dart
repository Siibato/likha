import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/account_detail_page.dart';
import 'package:likha/presentation/pages/admin/widgets/account_tile.dart';
import 'package:likha/presentation/pages/admin/widgets/search_bar.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class AccountManagementPage extends ConsumerStatefulWidget {
  const AccountManagementPage({super.key});

  @override
  ConsumerState<AccountManagementPage> createState() =>
      _AccountManagementPageState();
}

class _AccountManagementPageState
    extends ConsumerState<AccountManagementPage> {
  String _searchQuery = '';

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
            color: Color(0xFF404040),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Management',
          style: TextStyle(
            color: Color(0xFF202020),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          AdminSearchBar(
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          Expanded(
            child: adminState.isLoading && adminState.accounts.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2B2B2B),
                      strokeWidth: 2.5,
                    ),
                  )
                : filteredAccounts.isEmpty
                    ? const Center(
                        child: Text(
                          'No accounts found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF999999),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF2B2B2B),
                        onRefresh: () =>
                            ref.read(adminProvider.notifier).loadAccounts(),
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