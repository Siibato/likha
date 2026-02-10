import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/auth/entities/user.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(adminProvider.notifier).clearMessages();
        // Reload activity logs after changes
        ref.read(adminProvider.notifier).loadActivityLogs(widget.user.id);
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(adminProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(user.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EditableInfoRow(
                      label: 'Username',
                      value: user.username,
                      onEdit: adminState.isLoading
                          ? null
                          : () => _showEditDialog(
                                context,
                                title: 'Edit Username',
                                currentValue: user.username,
                                onSave: (value) {
                                  ref
                                      .read(adminProvider.notifier)
                                      .updateAccount(
                                        userId: user.id,
                                        username: value,
                                      );
                                },
                              ),
                    ),
                    _EditableInfoRow(
                      label: 'Full Name',
                      value: user.fullName,
                      onEdit: adminState.isLoading
                          ? null
                          : () => _showEditDialog(
                                context,
                                title: 'Edit Full Name',
                                currentValue: user.fullName,
                                onSave: (value) {
                                  ref
                                      .read(adminProvider.notifier)
                                      .updateAccount(
                                        userId: user.id,
                                        fullName: value,
                                      );
                                },
                              ),
                    ),
                    _InfoRow(label: 'Role', value: user.role),
                    _InfoRow(label: 'Status', value: user.accountStatus),
                    _InfoRow(
                      label: 'Created',
                      value: user.createdAt.toString().split('.')[0],
                    ),
                    if (user.activatedAt != null)
                      _InfoRow(
                        label: 'Activated',
                        value: user.activatedAt.toString().split('.')[0],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Actions',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.accountStatus != 'locked')
                  ElevatedButton.icon(
                    onPressed: adminState.isLoading
                        ? null
                        : () => ref
                            .read(adminProvider.notifier)
                            .lockAccount(user.id, true),
                    icon: const Icon(Icons.lock),
                    label: const Text('Lock Account'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[100]),
                  ),
                if (user.accountStatus == 'locked')
                  ElevatedButton.icon(
                    onPressed: adminState.isLoading
                        ? null
                        : () => ref
                            .read(adminProvider.notifier)
                            .lockAccount(user.id, false),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock Account'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100]),
                  ),
                ElevatedButton.icon(
                  onPressed: adminState.isLoading
                      ? null
                      : () => _confirmReset(context, user),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Password'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[100]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Activity Log',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (adminState.isLoading && adminState.activityLogs.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (adminState.activityLogs.isEmpty)
              const Text('No activity logs')
            else
              ...adminState.activityLogs.map((log) => Card(
                    child: ListTile(
                      leading: Icon(_actionIcon(log.action)),
                      title: Text(log.action.replaceAll('_', ' ')),
                      subtitle: Text(
                        '${log.createdAt.toString().split('.')[0]}'
                        '${log.details != null ? '\n${log.details}' : ''}',
                      ),
                    ),
                  )),
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
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty && value != currentValue) {
                Navigator.pop(ctx);
                onSave(value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
            'This will clear ${user.fullName}\'s password and set the account back to pending activation. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminProvider.notifier).resetAccount(user.id);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'account_created':
        return Icons.person_add;
      case 'account_activated':
        return Icons.check_circle;
      case 'account_updated':
        return Icons.edit;
      case 'password_reset':
        return Icons.refresh;
      case 'account_locked':
        return Icons.lock;
      case 'account_unlocked':
        return Icons.lock_open;
      case 'login':
        return Icons.login;
      default:
        return Icons.info;
    }
  }
}

class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _EditableInfoRow({
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
