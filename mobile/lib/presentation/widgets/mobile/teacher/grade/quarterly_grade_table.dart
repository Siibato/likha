import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/descriptor_badge.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_table_cells.dart';

/// Scrollable quarterly grade table with inline QG editing.
///
/// Displays WW / PT / QA weighted scores, the editable Quarterly Grade column,
/// and a descriptor badge. Manages its own editing state internally and
/// surfaces committed changes via [onQgChanged].
class QuarterlyGradeTable extends StatefulWidget {
  final List<Map<String, dynamic>> summary;
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;

  final void Function(String studentId, int grade) onQgChanged;

  const QuarterlyGradeTable({
    super.key,
    required this.summary,
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
    required this.onQgChanged,
  });

  @override
  State<QuarterlyGradeTable> createState() => _QuarterlyGradeTableState();
}

class _QuarterlyGradeTableState extends State<QuarterlyGradeTable> {
  String? _editingStudentId;
  final _qgCtrl = TextEditingController();
  final _qgFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _qgFocus.addListener(() {
      if (!_qgFocus.hasFocus && _editingStudentId != null) {
        _commitQg();
      }
    });
  }

  @override
  void dispose() {
    _qgCtrl.dispose();
    _qgFocus.dispose();
    super.dispose();
  }

  void _startQg(String studentId, int? current) {
    if (_editingStudentId != null) _commitQg();
    setState(() {
      _editingStudentId = studentId;
      _qgCtrl.text = current?.toString() ?? '';
      _qgCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _qgCtrl.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _qgFocus.requestFocus());
  }

  void _commitQg() {
    final grade = int.tryParse(_qgCtrl.text.trim());
    if (grade != null && _editingStudentId != null) {
      widget.onQgChanged(_editingStudentId!, grade);
    }
    if (mounted) setState(() => _editingStudentId = null);
  }

  void _cancelQg() {
    if (mounted) setState(() => _editingStudentId = null);
  }

  static double? _numOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _fmtScore(double? score) {
    if (score == null) return '--';
    if (score == score.roundToDouble()) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    const nameWidth = 130.0;
    const cellWidth = 80.0;
    const cellHeight = 44.0;
    const descriptorWidth = 130.0;

    final columns = [
      'WW (${widget.wwWeight.toStringAsFixed(0)}%)',
      'PT (${widget.ptWeight.toStringAsFixed(0)}%)',
      'QA (${widget.qaWeight.toStringAsFixed(0)}%)',
      'QG',
      'Descriptor',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    GradeTableCells.headerCell('Student', nameWidth,
                        align: Alignment.centerLeft),
                    ...columns.map((col) => GradeTableCells.headerCell(
                          col,
                          col == 'Descriptor' ? descriptorWidth : cellWidth,
                        )),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Data rows
              ...widget.summary.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final studentId = row['student_id'] as String? ?? '';
                final studentName = row['student_name'] as String? ?? 'Unknown';
                final wwScore = _numOrNull(row['ww_weighted_score']);
                final ptScore = _numOrNull(row['pt_weighted_score']);
                final qaScore = _numOrNull(row['qa_weighted_score']);
                final qg = _numOrNull(row['quarterly_grade'])?.round();
                final isEditing = _editingStudentId == studentId;

                return Container(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white
                        : AppColors.backgroundSecondary,
                  ),
                  child: Row(
                    children: [
                      GradeTableCells.dataCell(
                        studentName,
                        nameWidth,
                        cellHeight,
                        align: Alignment.centerLeft,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                      GradeTableCells.dataCell(
                          _fmtScore(wwScore), cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                          _fmtScore(ptScore), cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                          _fmtScore(qaScore), cellWidth, cellHeight),

                      // QG — inline editable
                      if (isEditing)
                        SizedBox(
                          width: cellWidth,
                          height: cellHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: CallbackShortcuts(
                              bindings: {
                                const SingleActivator(
                                    LogicalKeyboardKey.escape): _cancelQg,
                              },
                              child: TextField(
                                controller: _qgCtrl,
                                focusNode: _qgFocus,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(fontSize: 13),
                                onSubmitted: (_) => _commitQg(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                        color: AppColors.accentCharcoal,
                                        width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                        color: AppColors.accentCharcoal,
                                        width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                        color: AppColors.accentCharcoal,
                                        width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _startQg(studentId, qg),
                          child: GradeTableCells.dataCell(
                            qg?.toString() ?? '--',
                            cellWidth,
                            cellHeight,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: qg != null
                                  ? AppColors.foregroundPrimary
                                  : AppColors.foregroundLight,
                            ),
                          ),
                        ),

                      // Descriptor badge
                      SizedBox(
                        width: descriptorWidth,
                        child: DescriptorBadge(grade: qg, height: cellHeight),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
