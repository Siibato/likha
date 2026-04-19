import 'package:flutter/material.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';

class ActivityLogList extends StatelessWidget {
  final List<ActivityLog> logs;
  final bool isLoading;

  const ActivityLogList({
    super.key,
    required this.logs,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Color(0xFF2B2B2B),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text(
          'No activity logs',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
      );
    }

    return Column(
      children: logs.map((log) => _ActivityLogItem(log: log)).toList(),
    );
  }
}

class _ActivityLogItem extends StatelessWidget {
  final ActivityLog log;

  const _ActivityLogItem({required this.log});

  IconData _actionIcon(String action) {
    switch (action) {
      case 'account_created':
        return Icons.person_add_outlined;
      case 'account_activated':
        return Icons.check_circle_outline_rounded;
      case 'account_updated':
        return Icons.edit_outlined;
      case 'password_reset':
        return Icons.refresh_rounded;
      case 'account_locked':
        return Icons.lock_outline_rounded;
      case 'account_unlocked':
        return Icons.lock_open_rounded;
      case 'login':
        return Icons.login_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'account_created':
      case 'account_activated':
        return const Color(0xFF28A745);
      case 'account_updated':
        return const Color(0xFF0D6EFD);
      case 'password_reset':
        return const Color(0xFFFFC107);
      case 'account_locked':
        return const Color(0xFFDC3545);
      case 'account_unlocked':
        return const Color(0xFF28A745);
      case 'login':
        return const Color(0xFF6C757D);
      default:
        return const Color(0xFF999999);
    }
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatDate(DateTime date) {
    return date.toString().split('.')[0];
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _actionIcon(log.action),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatAction(log.action),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(log.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                  ),
                  if (log.details != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.details!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}