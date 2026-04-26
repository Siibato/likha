import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';

class TosGridTable extends StatefulWidget {
  final List<TosCompetency> competencies;
  final TableOfSpecifications tos;

  // ── Inline-editing callbacks (desktop) ────────────────────────────────────
  /// Called when a cognitive count cell is committed.
  /// [levelKey] is one of 'easy', 'medium', 'hard', 'remembering', 'understanding',
  /// 'applying', 'analyzing', 'evaluating', 'creating'.
  /// [newValue] is the override (0 means 0 items; null not used — empty = 0).
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
  // Inline-editing state — only one cell editable at a time.
  String? _editingCellKey; // "{fieldType}_{competencyId}"
  String? _editingCompetencyId;
  String? _editingFieldType; // 'competency' | 'days' | 'easy' | 'medium' | 'hard' | 'remembering' | 'understanding' | 'applying' | 'analyzing' | 'evaluating' | 'creating'
  String _originalValue = '';

  final _editController = TextEditingController();
  final _focusNode = FocusNode();

  bool get _inlineMode =>
      widget.onCellChanged != null ||
      widget.onCompetencyTextChanged != null ||
      widget.onDaysTaughtChanged != null;

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
      // Cognitive level: 'easy', 'medium', 'hard'
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isBloomsMode => widget.tos.classificationMode == 'blooms';

  List<String> get _cognitiveHeaders {
    if (_isBloomsMode) return ['Remembering', 'Understanding', 'Applying', 'Analyzing', 'Evaluating', 'Creating'];
    return ['Easy', 'Avg', 'Diff'];
  }

  String get _timeUnitLabel =>
      widget.tos.timeUnit == 'hours' ? 'Hours' : 'Days';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.competencies
        .fold<int>(0, (sum, c) => sum + c.timeUnitsTaught);

    const double fixedColWidth = 56 + 72 + 56; // Days + % + Total
    // Bloom mode needs wider columns for full names (Remembering, Understanding, etc.)
    final double cogColWidth = _isBloomsMode ? 80 : 48;
    final double totalFixed =
        fixedColWidth + _cognitiveHeaders.length * cogColWidth;

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
                        _headerCell('Competency', competencyWidth),
                        _headerCell(_timeUnitLabel, 56),
                        _headerCell('%', 72),
                        ..._cognitiveHeaders.map((h) => _headerCell(h, cogColWidth)),
                        _headerCell('Total', 56),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  // Pre-compute per-row totals so the TOTAL cell shows the
                  // real sum of cognitive cells, not the configured totalItems.
                  ...() {
                    int gridActualTotal = 0;
                    final rowWidgets = <Widget>[];
                    for (int idx = 0; idx < widget.competencies.length; idx++) {
                      final c = widget.competencies[idx];
                      final weight = totalDays > 0
                          ? (c.timeUnitsTaught) / totalDays * 100
                          : 0.0;
                      final targetItems = totalDays > 0
                          ? (weight * widget.tos.totalItems / 100).round()
                          : 0;
                      final easyItems = c.easyCount ??
                          (targetItems * widget.tos.easyPercentage / 100).round();
                      final mediumItems = c.mediumCount ??
                          (targetItems * widget.tos.mediumPercentage / 100).round();
                      final hardItems = c.hardCount ??
                          (targetItems * widget.tos.hardPercentage / 100).round();
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
                        rowTotal = easyItems + mediumItems + hardItems;
                      }
                      gridActualTotal += rowTotal;

                      rowWidgets.add(Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.borderLight,
                              width:
                                  idx < widget.competencies.length - 1 ? 1 : 0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _competencyCell(c, competencyWidth),
                            _daysCell(c, 56),
                            _staticCell(
                                '${weight.toStringAsFixed(1)}%', 72,
                                align: TextAlign.center),
                            ..._buildCognitiveCells(c, targetItems),
                            // Total = sum of cognitive cells, not targetItems
                            _staticCell('$rowTotal', 56,
                                align: TextAlign.center, bold: true),
                          ],
                        ),
                      ));
                    }
                    // Totals row
                    rowWidgets.add(Container(
                      decoration: const BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          _staticCell('TOTAL', competencyWidth, bold: true),
                          _staticCell('$totalDays', 56,
                              align: TextAlign.center, bold: true),
                          _staticCell('100%', 72,
                              align: TextAlign.center, bold: true),
                          ..._cognitiveHeaders.map(
                              (_) => _staticCell('-', cogColWidth,
                                  align: TextAlign.center)),
                          // Show actual sum of rows, not the configured totalItems
                          _staticCell('$gridActualTotal', 56,
                              align: TextAlign.center, bold: true),
                        ],
                      ),
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

  // ── Cell builders ──────────────────────────────────────────────────────────

  /// Competency text cell — inline-editable when onCompetencyTextChanged set.
  Widget _competencyCell(TosCompetency c, double width) {
    final label = c.competencyCode != null
        ? '${c.competencyCode} - ${c.competencyText}'
        : c.competencyText;
    final cellKey = 'competency_${c.id}';

    if (_inlineMode && widget.onCompetencyTextChanged != null) {
      if (_editingCellKey == cellKey) {
        return _inlineTextField(
          width: width,
          isNumeric: false,
          onCommit: _commitEdit,
          onCancel: _cancelEdit,
        );
      }
      return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () => _startEdit(c.id, 'competency', c.competencyText),
          child: _textCell(label, width,
              align: TextAlign.left, maxLines: 2),
        ),
      );
    }

    return _staticCell(label, width, maxLines: 2);
  }

  /// Days/hours cell — inline-editable when onDaysTaughtChanged set.
  Widget _daysCell(TosCompetency c, double width) {
    final cellKey = 'days_${c.id}';

    if (_inlineMode && widget.onDaysTaughtChanged != null) {
      if (_editingCellKey == cellKey) {
        return _inlineTextField(
          width: width,
          isNumeric: true,
          onCommit: _commitEdit,
          onCancel: _cancelEdit,
        );
      }
      return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () =>
              _startEdit(c.id, 'days', '${c.timeUnitsTaught}'),
          child: _textCell('${c.timeUnitsTaught}', width,
              align: TextAlign.center),
        ),
      );
    }

    return _staticCell('${c.timeUnitsTaught}', width, align: TextAlign.center);
  }

  List<Widget> _buildCognitiveCells(TosCompetency c, int targetItems) {
    final easyItems = c.easyCount ??
        (targetItems * widget.tos.easyPercentage / 100).round();
    final mediumItems = c.mediumCount ??
        (targetItems * widget.tos.mediumPercentage / 100).round();
    final hardItems = c.hardCount ??
        (targetItems * widget.tos.hardPercentage / 100).round();

    if (!_isBloomsMode) {
      // Difficulty mode: Easy | Avg | Diff
      return [
        _cognitiveCell(c, 'easy', '$easyItems', c.easyCount != null),
        _cognitiveCell(c, 'medium', '$mediumItems', c.mediumCount != null),
        _cognitiveCell(c, 'hard', '$hardItems', c.hardCount != null),
      ];
    }

    // Bloom's mode: R U Ap An E C - using individual fields
    final int r = c.rememberingCount ??
        (targetItems * widget.tos.rememberingPercentage / 100).round();
    final int u = c.understandingCount ??
        (targetItems * widget.tos.understandingPercentage / 100).round();
    final int ap = c.applyingCount ??
        (targetItems * widget.tos.applyingPercentage / 100).round();
    final int an = c.analyzingCount ??
        (targetItems * widget.tos.analyzingPercentage / 100).round();
    final int e = c.evaluatingCount ??
        (targetItems * widget.tos.evaluatingPercentage / 100).round();
    final int bl = c.creatingCount ??
        (targetItems * widget.tos.creatingPercentage / 100).round();

    return [
      _cognitiveCell(c, 'remembering', '$r', c.rememberingCount != null),
      _cognitiveCell(c, 'understanding', '$u', c.understandingCount != null),
      _cognitiveCell(c, 'applying', '$ap', c.applyingCount != null),
      _cognitiveCell(c, 'analyzing', '$an', c.analyzingCount != null),
      _cognitiveCell(c, 'evaluating', '$e', c.evaluatingCount != null),
      _cognitiveCell(c, 'creating', '$bl', c.creatingCount != null),
    ];
  }

  /// A single cognitive-level cell.
  Widget _cognitiveCell(
    TosCompetency c,
    String levelKey,
    String displayValue,
    bool isOverride,
  ) {
    // Bloom mode needs wider columns for full names
    final double width = _isBloomsMode ? 80 : 48;

    // Inline editing mode
    if (_inlineMode && widget.onCellChanged != null) {
      final cellKey = '${levelKey}_${c.id}';
      if (_editingCellKey == cellKey) {
        return _inlineTextField(
          width: width,
          isNumeric: true,
          onCommit: _commitEdit,
          onCancel: _cancelEdit,
        );
      }
      final overrideForLevel = switch (levelKey) {
        'easy' => c.easyCount,
        'medium' => c.mediumCount,
        'hard' => c.hardCount,
        'remembering' => c.rememberingCount,
        'understanding' => c.understandingCount,
        'applying' => c.applyingCount,
        'analyzing' => c.analyzingCount,
        'evaluating' => c.evaluatingCount,
        'creating' => c.creatingCount,
        _ => null,
      };
      return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () => _startEdit(
              c.id, levelKey, overrideForLevel?.toString() ?? displayValue),
          child: SizedBox(
            width: width,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isOverride ? FontWeight.w700 : FontWeight.w400,
                  color: isOverride
                      ? AppColors.accentCharcoal
                      : AppColors.accentCharcoal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    // Legacy dialog-tap mode (mobile)
    return GestureDetector(
      onTap: widget.onCellTap == null
          ? null
          : () {
              final override = switch (levelKey) {
                'easy' => c.easyCount,
                'medium' => c.mediumCount,
                'hard' => c.hardCount,
                'remembering' => c.rememberingCount,
                'understanding' => c.understandingCount,
                'applying' => c.applyingCount,
                'analyzing' => c.analyzingCount,
                'evaluating' => c.evaluatingCount,
                'creating' => c.creatingCount,
                _ => null,
              };
              widget.onCellTap!(c.id, levelKey, override);
            },
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
              color: isOverride
                  ? AppColors.accentCharcoal
                  : AppColors.accentCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ── Inline TextField ───────────────────────────────────────────────────────

  Widget _inlineTextField({
    required double width,
    required bool isNumeric,
    required VoidCallback onCommit,
    required VoidCallback onCancel,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): onCancel,
          },
          child: TextField(
            controller: _editController,
            focusNode: _focusNode,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: isNumeric
                ? const TextInputType.numberWithOptions(decimal: false)
                : TextInputType.text,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 6),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.accentCharcoal),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide:
                    const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.accentCharcoal),
              ),
            ),
            onSubmitted: (_) => onCommit(),
          ),
        ),
      ),
    );
  }

  // ── Primitive cell widgets ─────────────────────────────────────────────────

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundSecondary,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Read-only cell (no editing, no tap).
  Widget _staticCell(
    String text,
    double width, {
    TextAlign align = TextAlign.left,
    bool bold = false,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.accentCharcoal,
          ),
          textAlign: align,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Styled text for an editable cell's display state.
  Widget _textCell(
    String text,
    double width, {
    TextAlign align = TextAlign.left,
    bool bold = false,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.accentCharcoal,
          ),
          textAlign: align,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
