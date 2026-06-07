import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class SubmissionColumn {
  final String key;
  final String label;
  final bool numeric;
  final bool sortable;
  final Widget Function(dynamic value)? cellBuilder;

  const SubmissionColumn({
    required this.key,
    required this.label,
    this.numeric = false,
    this.sortable = false,
    this.cellBuilder,
  });
}

class SubmissionDataTable extends StatefulWidget {
  final List<SubmissionColumn> columns;
  final List<Map<String, dynamic>> rows;
  final ValueChanged<Map<String, dynamic>> onTap;
  final int rowsPerPage;

  const SubmissionDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.onTap,
    this.rowsPerPage = 20,
  });

  @override
  State<SubmissionDataTable> createState() => _SubmissionDataTableState();
}

class _SubmissionDataTableState extends State<SubmissionDataTable> {
  int _sortColumnIndex = -1;
  bool _sortAscending = true;
  int _currentPage = 0;

  List<Map<String, dynamic>> get _sortedRows {
    final sorted = List<Map<String, dynamic>>.from(widget.rows);
    if (_sortColumnIndex >= 0 && _sortColumnIndex < widget.columns.length) {
      final column = widget.columns[_sortColumnIndex];
      sorted.sort((a, b) {
        final aVal = a[column.key];
        final bVal = b[column.key];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return _sortAscending ? -1 : 1;
        if (bVal == null) return _sortAscending ? 1 : -1;
        int result;
        if (aVal is num && bVal is num) {
          result = aVal.compareTo(bVal);
        } else {
          result = aVal.toString().compareTo(bVal.toString());
        }
        return _sortAscending ? result : -result;
      });
    }
    return sorted;
  }

  List<Map<String, dynamic>> get _paginatedRows {
    final sorted = _sortedRows;
    final start = _currentPage * widget.rowsPerPage;
    if (start >= sorted.length) return [];
    final end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  int get _totalPages => (widget.rows.length / widget.rowsPerPage).ceil();

  void _onSort(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _currentPage = 0;
    });
  }

  @override
  void didUpdateWidget(covariant SubmissionDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.foregroundSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'No submissions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pageRows = _paginatedRows;
    final startIndex = _currentPage * widget.rowsPerPage;
    final endIndex = (startIndex + pageRows.length);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
              showCheckboxColumn: false,
              horizontalMargin: 20,
              columnSpacing: 24,
              dataRowMaxHeight: 56,
              headingRowColor: WidgetStateProperty.all(
                AppColors.backgroundTertiary,
              ),
              columns: List.generate(widget.columns.length, (index) {
                final col = widget.columns[index];
                return DataColumn(
                  label: Text(
                    col.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                  numeric: col.numeric,
                  onSort: col.sortable ? (_, __) => _onSort(index) : null,
                );
              }),
              sortColumnIndex:
                  _sortColumnIndex >= 0 ? _sortColumnIndex : null,
              sortAscending: _sortAscending,
              rows: pageRows.map((row) {
                return DataRow(
                  onSelectChanged: (_) => widget.onTap(row),
                  cells: widget.columns.map((col) {
                    final value = row[col.key];
                    if (col.cellBuilder != null) {
                      return DataCell(col.cellBuilder!(value));
                    }
                    return DataCell(
                      Text(
                        value?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
                ),
              ),
            );
          }),
          _buildPaginationFooter(startIndex + 1, endIndex, widget.rows.length),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int start, int end, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Showing $start-$end of $total',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            splashRadius: 18,
            tooltip: 'Previous page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            splashRadius: 18,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}
