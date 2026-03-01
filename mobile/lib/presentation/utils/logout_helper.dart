import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

/// Handles logout with confirmation if there are pending unsynced changes.
/// Shows a confirm dialog if user has pending sync operations.
Future<void> handleLogoutTap(BuildContext context, WidgetRef ref) async {
  final count = await sl<SyncQueue>().getPendingCount();

  if (!context.mounted) return;

  if (count > 0) {
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved offline changes'),
        content: Text(
          'You have $count change(s) that haven\'t synced to the server yet. '
          'Logging out now will permanently discard them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Logout anyway',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // ignore: use_build_context_synchronously
      ref.read(authProvider.notifier).logout();
    }
  } else {
    ref.read(authProvider.notifier).logout();
  }
}
