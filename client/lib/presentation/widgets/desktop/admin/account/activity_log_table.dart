import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/activity_log.dart';

class ActivityLogTable extends StatelessWidget {
  final List<ActivityLog> logs;
  final bool isLoading;

  const ActivityLogTable({
    super.key,
    required this.logs,
    required this.isLoading,
  });

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
      case 'account_unlocked':
        return AppColors.semanticSuccessAlt;
      case 'account_updated':
        return AppColors.accentCharcoal;
      case 'password_reset':
        return AppColors.accentAmber;
      case 'account_locked':
        return AppColors.semanticErrorDark;
      case 'login':
        return AppColors.foregroundSecondary;
      default:
        return AppColors.foregroundTertiary;
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Activity Log',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
              ),
            ),
          ),
          if (isLoading && logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No activity logs',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AppColors.backgroundTertiary),
                dataRowMaxHeight: 56,
                horizontalMargin: 24,
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text('Action', style: _headerStyle),
                  ),
                  DataColumn(
                    label: Text('Details', style: _headerStyle),
                  ),
                  DataColumn(
                    label: Text('Date', style: _headerStyle),
                  ),
                ],
                rows: logs.map((log) {
                  final color = _actionColor(log.action);
                  return DataRow(cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _actionIcon(log.action),
                              color: color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatAction(log.action),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foregroundDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(
                      log.details ?? '—',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundSecondary,
                      ),
                    )),
                    DataCell(Text(
                      _formatDate(log.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundTertiary,
                      ),
                    )),
                  ]);
                }).toList(),
              ),
              ),
            ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
