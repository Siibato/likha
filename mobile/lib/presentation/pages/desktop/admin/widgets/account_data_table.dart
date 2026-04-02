import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'account_actions_menu.dart';

class AccountDataTable extends StatefulWidget {
  final List<User> accounts;
  final ValueChanged<User> onTap;
  final void Function(User user, bool locked)? onLock;
  final ValueChanged<User>? onResetPassword;
  final ValueChanged<User>? onDelete;
  final int rowsPerPage;

  const AccountDataTable({
    super.key,
    required this.accounts,
    required this.onTap,
    this.onLock,
    this.onResetPassword,
    this.onDelete,
    this.rowsPerPage = 20,
  });

  @override
  State<AccountDataTable> createState() => _AccountDataTableState();
}

class _AccountDataTableState extends State<AccountDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _currentPage = 0;

  List<User> get _sortedAccounts {
    final sorted = List<User>.from(widget.accounts);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0:
          result = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
          break;
        case 2:
          result = a.role.compareTo(b.role);
          break;
        case 3:
          result = a.accountStatus.compareTo(b.accountStatus);
          break;
        default:
          result = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  int get _totalPages =>
      (widget.accounts.length / widget.rowsPerPage).ceil().clamp(1, 999);

  List<User> get _pageAccounts {
    final sorted = _sortedAccounts;
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    if (start >= sorted.length) return [];
    return sorted.sublist(start, end);
  }

  @override
  void didUpdateWidget(AccountDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accounts.length != oldWidget.accounts.length) {
      final maxPage = _totalPages - 1;
      if (_currentPage > maxPage) {
        _currentPage = maxPage.clamp(0, maxPage);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'activated':
        return const Color(0xFF28A745);
      case 'pending_activation':
        return const Color(0xFFFFC107);
      case 'locked':
        return const Color(0xFFDC3545);
      default:
        return AppColors.foregroundTertiary;
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get _hasActions =>
      widget.onLock != null ||
      widget.onResetPassword != null ||
      widget.onDelete != null;

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Text(
            'No accounts found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DataTable(
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor:
                  WidgetStateProperty.all(AppColors.backgroundTertiary),
              dataRowMaxHeight: 56,
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: [
                DataColumn(
                  label: const Text('Name', style: _headerStyle),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                const DataColumn(
                  label: Text('Username', style: _headerStyle),
                ),
                DataColumn(
                  label: const Text('Role', style: _headerStyle),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text('Status', style: _headerStyle),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                const DataColumn(
                  label: Text('Created', style: _headerStyle),
                ),
                if (_hasActions)
                  const DataColumn(
                    label: Text('', style: _headerStyle),
                  ),
              ],
              rows: _pageAccounts.map((user) {
                final isLocked = user.accountStatus == 'locked';
                return DataRow(
                  onSelectChanged: (_) => widget.onTap(user),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundTertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foregroundPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            user.fullName,
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
                      user.username,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundSecondary,
                      ),
                    )),
                    DataCell(Text(
                      user.role[0].toUpperCase() + user.role.substring(1),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundSecondary,
                      ),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(user.accountStatus)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(user.accountStatus),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(user.accountStatus),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      _formatDate(user.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundTertiary,
                      ),
                    )),
                    if (_hasActions)
                      DataCell(
                        AccountActionsMenu(
                          user: user,
                          onLock: widget.onLock,
                          onResetPassword: widget.onResetPassword,
                          onDelete: widget.onDelete,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        // Pagination
        if (_totalPages > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_currentPage * widget.rowsPerPage + 1}\u2013${((_currentPage + 1) * widget.rowsPerPage).clamp(0, widget.accounts.length)} of ${widget.accounts.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.foregroundTertiary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  ...List.generate(
                    _totalPages.clamp(0, 5),
                    (i) {
                      final page =
                          _currentPage < 3 ? i : _currentPage + i - 2;
                      if (page >= _totalPages) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() => _currentPage = page),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: page == _currentPage
                                  ? AppColors.foregroundDark
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${page + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: page == _currentPage
                                    ? Colors.white
                                    : AppColors.foregroundSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
