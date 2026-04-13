import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Base data table widget that provides common functionality for all desktop data tables
/// including sorting, pagination, and consistent styling.
class BaseDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<DataColumn> columns;
  final Widget Function(BuildContext context, T item, int index) rowBuilder;
  final int rowsPerPage;
  final bool showPagination;
  final bool showCheckboxColumn;
  final double? dataRowMaxHeight;
  final double horizontalMargin;
  final double columnSpacing;
  final Widget? emptyState;
  final VoidCallback? onRefresh;
  final ValueChanged<T>? onTap;

  const BaseDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    this.rowsPerPage = 20,
    this.showPagination = true,
    this.showCheckboxColumn = false,
    this.dataRowMaxHeight = 56,
    this.horizontalMargin = 20,
    this.columnSpacing = 24,
    this.emptyState,
    this.onRefresh,
    this.onTap,
  });

  @override
  State<BaseDataTable<T>> createState() => _BaseDataTableState<T>();
}

class _BaseDataTableState<T> extends State<BaseDataTable<T>> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _currentPage = 0;
  bool _isLoading = false;

  List<T> get _sortedItems {
    final sorted = List<T>.from(widget.items);
    // Default sorting by first column if no specific sort is provided
    // Subclasses can override this behavior
    return sorted;
  }

  int get _totalPages =>
      (widget.items.length / widget.rowsPerPage).ceil().clamp(1, 999);

  List<T> get _pageItems {
    final sorted = _sortedItems;
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    if (start >= sorted.length) return [];
    return sorted.sublist(start, end);
  }

  void _handleSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _handlePageChange(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      setState(() => _isLoading = true);
      try {
        widget.onRefresh!();
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.emptyState != null) {
      return widget.emptyState!;
    }

    if (widget.items.isEmpty) {
      return const _DefaultEmptyState();
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
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStateProperty.all(AppColors.backgroundTertiary),
              dataRowMaxHeight: widget.dataRowMaxHeight,
              horizontalMargin: widget.horizontalMargin,
              columnSpacing: widget.columnSpacing,
              showCheckboxColumn: widget.showCheckboxColumn,
              columns: widget.columns.map((column) {
                if (column.onSort != null) {
                  return DataColumn(
                    label: column.label,
                    numeric: column.numeric,
                    onSort: _handleSort,
                  );
                }
                return column;
              }).toList(),
              rows: _pageItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return DataRow(
                  key: ValueKey(item),
                  onSelectChanged: widget.onTap != null 
                      ? (_) => widget.onTap!(item)
                      : widget.showCheckboxColumn ? (_) {} : null,
                  cells: [
                    DataCell(
                      Builder(
                        builder: (context) => widget.rowBuilder(context, item, index),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (widget.showPagination && _totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(),
        ],
        if (widget.onRefresh != null) ...[
          const SizedBox(height: 16),
          _buildRefreshButton(),
        ],
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${_currentPage * widget.rowsPerPage + 1}â\u0080\u0093${((_currentPage + 1) * widget.rowsPerPage).clamp(0, widget.items.length)} of ${widget.items.length}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: _currentPage > 0 ? () => _handlePageChange(_currentPage - 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: _currentPage < _totalPages - 1 ? () => _handlePageChange(_currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _isLoading ? null : _handleRefresh,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppColors.foregroundPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: Text(_isLoading ? 'Refreshing...' : 'Refresh'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.foregroundSecondary,
          ),
        ),
      ],
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.borderLight),
            SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Configuration class for data table styling and behavior
class DataTableConfig<T> {
  final List<DataColumn> columns;
  final Widget Function(BuildContext context, T item, int index) rowBuilder;
  final Widget? emptyState;
  final int rowsPerPage;
  final bool showPagination;
  final bool showCheckboxColumn;
  final VoidCallback? onRefresh;
  final ValueChanged<T>? onTap;

  const DataTableConfig({
    required this.columns,
    required this.rowBuilder,
    this.emptyState,
    this.rowsPerPage = 20,
    this.showPagination = true,
    this.showCheckboxColumn = false,
    this.onRefresh,
    this.onTap,
  });

  /// Creates a BaseDataTable with this configuration
  Widget build(List<T> items) {
    return BaseDataTable<T>(
      items: items,
      columns: columns,
      rowBuilder: rowBuilder,
      emptyState: emptyState,
      rowsPerPage: rowsPerPage,
      showPagination: showPagination,
      showCheckboxColumn: showCheckboxColumn,
      onRefresh: onRefresh,
      onTap: onTap,
    );
  }
}

/// Common header style for data tables
const TextStyle dataTableHeaderStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: AppColors.foregroundSecondary,
);
