import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/pages/admin/account_detail_page.dart';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'activated':
        return Colors.green;
      case 'pending_activation':
        return Colors.orange;
      case 'locked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'activated':
        return 'Active';
      case 'pending_activation':
        return 'Pending';
      case 'locked':
        return 'Locked';
      default:
        return status;
    }
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
      appBar: AppBar(title: const Text('Account Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: adminState.isLoading && adminState.accounts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredAccounts.isEmpty
                    ? const Center(child: Text('No accounts found'))
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(adminProvider.notifier).loadAccounts(),
                        child: ListView.builder(
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final user = filteredAccounts[index];
                            return _AccountTile(
                              user: user,
                              statusColor: _statusColor(user.accountStatus),
                              statusLabel: _statusLabel(user.accountStatus),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AccountDetailPage(user: user),
                                ),
                              ).then((_) =>
                                  ref.read(adminProvider.notifier).loadAccounts()),
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

class _AccountTile extends StatelessWidget {
  final User user;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _AccountTile({
    required this.user,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.fullName[0].toUpperCase()),
      ),
      title: Text(user.fullName),
      subtitle: Text('${user.username} - ${user.role}'),
      trailing: Chip(
        label: Text(
          statusLabel,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: statusColor,
      ),
      onTap: onTap,
    );
  }
}
