import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_competency_data_row.dart';
import 'package:likha/presentation/widgets/mobile/teacher/tos/tos_table_cells.dart';
import 'package:likha/presentation/widgets/shared/primitives/app_divider.dart';

class TosGridTable extends StatefulWidget {
  final List<TosCompetency> competencies;
  final TableOfSpecifications tos;

  // ── Inline-editing callbacks (desktop) ────────────────────────────────────
  /// Called when a cognitive count cell is committed.
  /// [levelKey] is one of 'easy', 'medium', 'hard', 'remembering', 'understanding',
  /// 'applying', 'analyzing', 'evaluating', 'creating'.
  final void Function(String competencyId, String levelKey, int? newValue)?
      onCellChanged;

  /// Called when the competency text cell is committed.
  final void Function(String competencyId, String newText)?
      onCompetencyTextChanged;

  /// Called when the days/hours cell is committed.
  final void Function(String competencyId, int newDays)? onDaysTaughtChanged;

  // ── Dialog-based tap callback (mobile / legacy) ────────────────────────────
  /// Called when a cognitive cell is tapped (dialog approach).
  /// Used by mobile detail page. Ignored when [onCellChanged] is provided.
  final void Function(String competencyId, String levelKey, int? currentOverride)?
      onCellTap;

  const TosGridTable({
    super.key,
    required this.competencies,
    required this.tos,
    this.onCellChanged,
    this.onCompetencyTextChanged,
    this.onDaysTaughtChanged,
    this.onCellTap,
  });

  @override
  State<TosGridTable> createState() => _TosGridTableState();
}

class _TosGridTableState extends State<TosGridTable> {
  String? _editingCellKey;
  String? _editingCompetencyId;
  String? _editingFieldType;
  String _originalValue = '';

  final _editController = TextEditingController();
  final _focusNode = FocusNode();

  bool get _inlineMode =>
      widget.onCellChanged != null ||
      widget.onCompetencyTextChanged != null ||
      widget.onDaysTaughtChanged != null;

  bool get _isBloomsMode => widget.tos.classificationMode == 'blooms';

  List<String> get _cognitiveHeaders {
    if (_isBloomsMode) {
      return ['Remembering', 'Understanding', 'Applying', 'Analyzing', 'Evaluating', 'Creating'];
    }
    return ['Easy', 'Avg', 'Diff'];
  }

  String get _timeUnitLabel => widget.tos.timeUnit == 'hours' ? 'Hours' : 'Days';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editingCellKey != null) {
      _commitEdit();
    }
  }

  void _startEdit(String competencyId, String fieldType, String editValue) {
    if (_editingCellKey != null) _commitEdit();
    setState(() {
      _editingCellKey = '${fieldType}_$competencyId';
      _editingCompetencyId = competencyId;
      _editingFieldType = fieldType;
      _originalValue = editValue;
      _editController.text = editValue;
      _editController.selection = TextSelection.fromPosition(
        TextPosition(offset: editValue.length),
      );
    });
  }

  void _commitEdit() {
    if (_editingCellKey == null) return;
    final val = _editController.text.trim();
    final id = _editingCompetencyId!;
    final type = _editingFieldType!;

    if (type == 'competency') {
      if (val.isNotEmpty && val != _originalValue) {
        widget.onCompetencyTextChanged?.call(id, val);
      }
    } else if (type == 'days') {
      final days = int.tryParse(val);
      if (days != null && days > 0 && val != _originalValue) {
        widget.onDaysTaughtChanged?.call(id, days);
      }
    } else {
      if (val != _originalValue) {
        final count = val.isEmpty ? 0 : (int.tryParse(val) ?? 0);
        widget.onCellChanged?.call(id, type, count);
      }
    }

    setState(() {
      _editingCellKey = null;
      _editingCompetencyId = null;
      _editingFieldType = null;
    });
  }

  void _cancelEdit() {
    _editController.text = _originalValue;
    setState(() {
      _editingCellKey = null;
      _editingCompetencyId = null;
      _editingFieldType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.competencies.fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    const double fixedColWidth = 56 + 72 + 56;
    final double cogColWidth = _isBloomsMode ? 80 : 48;
    final double totalFixed = fixedColWidth + _cognitiveHeaders.length * cogColWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double competencyWidth =
            (constraints.maxWidth - totalFixed).clamp(120.0, double.infinity);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        TosTableCells.headerCell('Competency', competencyWidth),
                        TosTableCells.headerCell(_timeUnitLabel, 56),
                        TosTableCells.headerCell('%', 72),
                        ..._cognitiveHeaders.map((h) => TosTableCells.headerCell(h, cogColWidth)),
                        TosTableCells.headerCell('Total', 56),
                      ],
                    ),
                  ),
                  const AppDivider(),

                  // Competency rows
                  ...() {
                    int gridActualTotal = 0;
                    final rowWidgets = <Widget>[];

                    for (int idx = 0; idx < widget.competencies.length; idx++) {
                      final c = widget.competencies[idx];
                      final targetItems = totalDays > 0
                          ? ((c.timeUnitsTaught / totalDays * 100) * widget.tos.totalItems / 100).round()
                          : 0;

                      // Compute row total for the totals-row accumulator
                      final int rowTotal;
                      if (_isBloomsMode) {
                        final r = c.rememberingCount ?? (targetItems * widget.tos.rememberingPercentage / 100).round();
                        final u = c.understandingCount ?? (targetItems * widget.tos.understandingPercentage / 100).round();
                        final ap = c.applyingCount ?? (targetItems * widget.tos.applyingPercentage / 100).round();
                        final an = c.analyzingCount ?? (targetItems * widget.tos.analyzingPercentage / 100).round();
                        final e = c.evaluatingCount ?? (targetItems * widget.tos.evaluatingPercentage / 100).round();
                        final bl = c.creatingCount ?? (targetItems * widget.tos.creatingPercentage / 100).round();
                        rowTotal = r + u + ap + an + e + bl;
                      } else {
                        final easy = c.easyCount ?? (targetItems * widget.tos.easyPercentage / 100).round();
                        final med = c.mediumCount ?? (targetItems * widget.tos.mediumPercentage / 100).round();
                        final hard = c.hardCount ?? (targetItems * widget.tos.hardPercentage / 100).round();
                        rowTotal = easy + med + hard;
                      }
                      gridActualTotal += rowTotal;

                      rowWidgets.add(Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.borderLight,
                              width: idx < widget.competencies.length - 1 ? 1 : 0,
                            ),
                          ),
                        ),
                        child: TosCompetencyDataRow(
                          competency: c,
                          tos: widget.tos,
                          targetItems: targetItems,
                          competencyWidth: competencyWidth,
                          totalDays: totalDays,
                          editingCellKey: _editingCellKey,
                          editController: _editController,
                          focusNode: _focusNode,
                          inlineMode: _inlineMode,
                          onStartEdit: _startEdit,
                          onCommitEdit: _commitEdit,
                          onCancelEdit: _cancelEdit,
                          onCellTap: widget.onCellTap,
                        ),
                      ));
                    }

                    // Totals row
                    rowWidgets.add(_buildTotalsRow(
                      competencyWidth: competencyWidth,
                      cogColWidth: cogColWidth,
                      totalDays: totalDays,
                      gridActualTotal: gridActualTotal,
                    ));

                    return rowWidgets;
                  }(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalsRow({
    required double competencyWidth,
    required double cogColWidth,
    required int totalDays,
    required int gridActualTotal,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(11),
          bottomRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: [
          TosTableCells.staticCell('TOTAL', competencyWidth, bold: true),
          TosTableCells.staticCell('$totalDays', 56, align: TextAlign.center, bold: true),
          TosTableCells.staticCell('100%', 72, align: TextAlign.center, bold: true),
          ..._cognitiveHeaders.map((_) => TosTableCells.staticCell('-', cogColWidth, align: TextAlign.center)),
          TosTableCells.staticCell('$gridActualTotal', 56, align: TextAlign.center, bold: true),
        ],
      ),
    );
  }
}
