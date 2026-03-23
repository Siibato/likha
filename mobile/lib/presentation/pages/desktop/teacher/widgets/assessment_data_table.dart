import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

class AssessmentDataTable extends StatefulWidget {
  final List<Assessment> assessments;
  final ValueChanged<Assessment> onTap;
  final int rowsPerPage;

  const AssessmentDataTable({
    super.key,
    required this.assessments,
    required this.onTap,
    this.rowsPerPage = 20,
  });

  @override
  State<AssessmentDataTable> createState() => _AssessmentDataTableState();
}

class _AssessmentDataTableState extends State<AssessmentDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _currentPage = 0;

  List<Assessment> get _sortedAssessments {
    final sorted = List<Assessment>.from(widget.assessments);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0:
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 2:
          result = (a.isPublished ? 1 : 0).compareTo(b.isPublished ? 1 : 0);
          break;
        default:
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  int get _totalPages =>
      (widget.assessments.length / widget.rowsPerPage).ceil().clamp(1, 999);

  List<Assessment> get _pageAssessments {
    final sorted = _sortedAssessments;
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    if (start >= sorted.length) return [];
    return sorted.sublist(start, end);
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assessments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.quiz_outlined, size: 48, color: AppColors.borderLight),
              SizedBox(height: 12),
              Text(
                'No assessments yet',
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
                  label: Text('Questions', style: _headerStyle),
                  numeric: true,
                ),
                DataColumn(
                  label: const Text('Status', style: _headerStyle),
                  onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i;
                    _sortAscending = asc;
                  }),
                ),
                const DataColumn(
                  label: Text('Open', style: _headerStyle),
                ),
                const DataColumn(
                  label: Text('Close', style: _headerStyle),
                ),
                const DataColumn(
                  label: Text('Submissions', style: _headerStyle),
                  numeric: true,
                ),
              ],
              rows: _pageAssessments.map((assessment) {
                return DataRow(
                  onSelectChanged: (_) => widget.onTap(assessment),
                  cells: [
                    DataCell(Text(
                      assessment.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundDark,
                      ),
                    )),
                    DataCell(Text(
                      '${assessment.questionCount}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundSecondary,
                      ),
                    )),
                    DataCell(_StatusBadge(
                      isPublished: assessment.isPublished,
                    )),
                    DataCell(Text(
                      _formatDate(assessment.openAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundTertiary,
                      ),
                    )),
                    DataCell(Text(
                      _formatDate(assessment.closeAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foregroundTertiary,
                      ),
                    )),
                    DataCell(Text(
                      '${assessment.submissionCount}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.foregroundSecondary,
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
          'Showing ${_currentPage * widget.rowsPerPage + 1}–${((_currentPage + 1) * widget.rowsPerPage).clamp(0, widget.assessments.length)} of ${widget.assessments.length}',
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

class _StatusBadge extends StatelessWidget {
  final bool isPublished;

  const _StatusBadge({required this.isPublished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFF28A745).withValues(alpha: 0.12)
            : AppColors.foregroundTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF28A745)
              : AppColors.foregroundTertiary,
        ),
      ),
    );
  }
}
