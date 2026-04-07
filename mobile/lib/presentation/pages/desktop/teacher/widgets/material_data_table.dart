import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/learning_materials/entities/learning_material.dart';

class MaterialDataTable extends StatefulWidget {
  final List<LearningMaterial> materials;
  final ValueChanged<LearningMaterial> onTap;
  final int rowsPerPage;

  const MaterialDataTable({
    super.key,
    required this.materials,
    required this.onTap,
    this.rowsPerPage = 20,
  });

  @override
  State<MaterialDataTable> createState() => _MaterialDataTableState();
}

class _MaterialDataTableState extends State<MaterialDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _currentPage = 0;

  List<LearningMaterial> get _sortedMaterials {
    final sorted = List<LearningMaterial>.from(widget.materials);
    sorted.sort((a, b) {
      final result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  int get _totalPages =>
      (widget.materials.length / widget.rowsPerPage).ceil().clamp(1, 999);

  List<LearningMaterial> get _pageMaterials {
    final sorted = _sortedMaterials;
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    if (start >= sorted.length) return [];
    return sorted.sublist(start, end);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.materials.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.library_books_outlined, size: 48, color: AppColors.borderLight),
              SizedBox(height: 12),
              Text(
                'No modules yet',
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
              headingRowColor:
                  WidgetStateProperty.all(AppColors.backgroundTertiary),
              dataRowMaxHeight: 56,
              horizontalMargin: 20,
              columnSpacing: 24,
              showCheckboxColumn: false,
              columns: [
                DataColumn(
                  label: const Text('Title', style: _headerStyle),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                const DataColumn(
                  label: Text('Files', style: _headerStyle),
                  numeric: true,
                ),
                const DataColumn(
                  label: Text('Created', style: _headerStyle),
                ),
                const DataColumn(
                  label: Text('Updated', style: _headerStyle),
                ),
              ],
              rows: _pageMaterials.map((material) {
                return DataRow(
                  onSelectChanged: (_) => widget.onTap(material),
                  cells: [
                    DataCell(Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundDark,
                      ),
                    )),
                    DataCell(Text(
                      '${material.fileCount}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundSecondary,
                      ),
                    )),
                    DataCell(Text(
                      _formatDate(material.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundTertiary,
                      ),
                    )),
                    DataCell(Text(
                      _formatDate(material.updatedAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundTertiary,
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(),
        ],
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${_currentPage * widget.rowsPerPage + 1}–${((_currentPage + 1) * widget.rowsPerPage).clamp(0, widget.materials.length)} of ${widget.materials.length}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed:
                  _currentPage > 0 ? () => setState(() => _currentPage--) : null,
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
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundSecondary,
  );
}
