import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

class GradeSpreadsheet extends StatefulWidget {
  final List<Participant> students;
  final List<GradeItem> items;
  final Map<String, List<GradeScore>> scoresByItem;
  final String weightLabel;

  /// Inline editing callback. When provided, cells become inline-editable.
  /// [existingScore] may be null (no score yet) or non-null (may be auto-populated).
  final void Function(
    String studentId,
    String itemId,
    GradeScore? existingScore,
    double newScore,
  )? onScoreChanged;

  /// Fallback tap callback used when [onScoreChanged] is null.
  final void Function(Participant participant, GradeItem item,
      GradeScore? existingScore)? onCellTap;

  final void Function(GradeItem item) onHeaderTap;

  const GradeSpreadsheet({
    super.key,
    required this.students,
    required this.items,
    required this.scoresByItem,
    required this.weightLabel,
    required this.onHeaderTap,
    this.onScoreChanged,
    this.onCellTap,
  });

  static const double _frozenColWidth = 180;
  static const double _itemColWidth = 80;
  static const double _rowHeight = 44;
  static const double _headerHeight = 56;

  @override
  State<GradeSpreadsheet> createState() => _GradeSpreadsheetState();
}

class _GradeSpreadsheetState extends State<GradeSpreadsheet> {
  String? _editingKey; // "${studentId}_${itemId}"
  String? _editingStudentId;
  String? _editingItemId;
  GradeScore? _editingExistingScore;

  final _editController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _editingKey != null) {
        _commitEdit();
      }
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _inlineMode => widget.onScoreChanged != null;

  void _startEdit(
    String studentId,
    String itemId,
    GradeScore? existingScore,
    String currentValue,
  ) {
    if (_editingKey != null) _commitEdit();
    setState(() {
      _editingKey = '${studentId}_$itemId';
      _editingStudentId = studentId;
      _editingItemId = itemId;
      _editingExistingScore = existingScore;
      _editController.text = currentValue == '--' ? '' : currentValue;
      _editController.selection = TextSelection.fromPosition(
        TextPosition(offset: _editController.text.length),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _commitEdit() {
    final raw = _editController.text.trim();
    final score = double.tryParse(raw);
    if (score != null && _editingStudentId != null && _editingItemId != null) {
      widget.onScoreChanged?.call(
        _editingStudentId!,
        _editingItemId!,
        _editingExistingScore,
        score,
      );
    }
    _clearEditState();
  }

  void _cancelEdit() => _clearEditState();

  void _clearEditState() {
    if (!mounted) return;
    setState(() {
      _editingKey = null;
      _editingStudentId = null;
      _editingItemId = null;
      _editingExistingScore = null;
    });
  }

  /// Build a lookup: studentId -> { gradeItemId -> GradeScore }
  Map<String, Map<String, GradeScore>> _buildScoreLookup() {
    final lookup = <String, Map<String, GradeScore>>{};
    for (final entry in widget.scoresByItem.entries) {
      for (final score in entry.value) {
        lookup
            .putIfAbsent(score.studentId, () => <String, GradeScore>{})
            [score.gradeItemId] = score;
      }
    }
    return lookup;
  }

  String _formatScore(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  double? _computePercentage(
    Participant participant,
    Map<String, Map<String, GradeScore>> scoreLookup,
  ) {
    if (widget.items.isEmpty) return null;

    final studentScores = scoreLookup[participant.student.id];
    if (studentScores == null || studentScores.isEmpty) return null;

    double totalEarned = 0;
    double totalPossible = 0;

    for (final item in widget.items) {
      final score = studentScores[item.id];
      final effective = score?.effectiveScore;
      if (effective != null) {
        totalEarned += effective;
        totalPossible += item.totalPoints;
      }
    }

    if (totalPossible == 0) return null;
    return (totalEarned / totalPossible) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final scoreLookup = _buildScoreLookup();
    final scrollController = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weight label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.weightLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundPrimary,
            ),
          ),
        ),
        // Spreadsheet
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frozen first column (student names)
              _buildFrozenColumn(scoreLookup),
              // Scrollable item columns + percentage column
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: _buildScrollableColumns(scoreLookup),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrozenColumn(
      Map<String, Map<String, GradeScore>> scoreLookup) {
    return SizedBox(
      width: GradeSpreadsheet._frozenColWidth,
      child: Column(
        children: [
          // Header cell
          Container(
            height: GradeSpreadsheet._headerHeight,
            width: GradeSpreadsheet._frozenColWidth,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.backgroundTertiary,
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
                right: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: const Text(
              'Student',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          // Student name rows
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemExtent: GradeSpreadsheet._rowHeight,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                return Container(
                  width: GradeSpreadsheet._frozenColWidth,
                  height: GradeSpreadsheet._rowHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? AppColors.backgroundPrimary
                        : AppColors.backgroundTertiary,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderLight),
                      right: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: Text(
                    student.student.fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.foregroundPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableColumns(
      Map<String, Map<String, GradeScore>> scoreLookup) {
    final totalWidth =
        (widget.items.length * GradeSpreadsheet._itemColWidth) +
            GradeSpreadsheet._itemColWidth; // +1 for percentage col

    return SizedBox(
      width: totalWidth,
      child: Column(
        children: [
          // Header row
          SizedBox(
            height: GradeSpreadsheet._headerHeight,
            child: Row(
              children: [
                // Item headers
                ...widget.items.map((item) => _buildItemHeader(item)),
                // Percentage header
                Container(
                  width: GradeSpreadsheet._itemColWidth,
                  height: GradeSpreadsheet._headerHeight,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderLight),
                      right: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemExtent: GradeSpreadsheet._rowHeight,
              itemBuilder: (context, index) {
                final participant = widget.students[index];
                final studentScores =
                    scoreLookup[participant.student.id] ?? {};
                final percentage =
                    _computePercentage(participant, scoreLookup);

                return SizedBox(
                  height: GradeSpreadsheet._rowHeight,
                  child: Row(
                    children: [
                      // Score cells
                      ...widget.items.map((item) {
                        final score = studentScores[item.id];
                        return _buildScoreCell(
                          participant: participant,
                          item: item,
                          score: score,
                          rowIndex: index,
                        );
                      }),
                      // Percentage cell
                      Container(
                        width: GradeSpreadsheet._itemColWidth,
                        height: GradeSpreadsheet._rowHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? AppColors.backgroundPrimary
                              : AppColors.backgroundTertiary,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.borderLight),
                            right: BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        child: Text(
                          percentage != null
                              ? '${_formatScore(percentage)}%'
                              : '--',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: percentage != null
                                ? AppColors.foregroundPrimary
                                : AppColors.foregroundTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader(GradeItem item) {
    return GestureDetector(
      onTap: () => widget.onHeaderTap(item),
      child: Container(
        width: GradeSpreadsheet._itemColWidth,
        height: GradeSpreadsheet._headerHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          color: AppColors.backgroundTertiary,
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight),
            right: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '/${_formatScore(item.totalPoints)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.foregroundTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCell({
    required Participant participant,
    required GradeItem item,
    required GradeScore? score,
    required int rowIndex,
  }) {
    final cellKey = '${participant.student.id}_${item.id}';
    final isEditing = _editingKey == cellKey && _inlineMode;
    final effective = score?.effectiveScore;
    final isOverride = score?.overrideScore != null;

    final bgColor = rowIndex.isEven
        ? AppColors.backgroundPrimary
        : AppColors.backgroundTertiary;

    final border = BoxDecoration(
      color: bgColor,
      border: const Border(
        bottom: BorderSide(color: AppColors.borderLight),
        right: BorderSide(color: AppColors.borderLight),
      ),
    );

    if (isEditing) {
      return Container(
        width: GradeSpreadsheet._itemColWidth,
        height: GradeSpreadsheet._rowHeight,
        decoration: BoxDecoration(
          color: bgColor,
          border: const Border(
            bottom: BorderSide(color: AppColors.borderLight),
            right: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: _inlineTextField(),
      );
    }

    if (_inlineMode) {
      // Inline-editable cell
      final displayText =
          effective != null ? _formatScore(effective) : '--';
      return GestureDetector(
        onTap: () => _startEdit(
          participant.student.id,
          item.id,
          score,
          effective != null ? _formatScore(effective) : '',
        ),
        child: Container(
          width: GradeSpreadsheet._itemColWidth,
          height: GradeSpreadsheet._rowHeight,
          alignment: Alignment.center,
          decoration: border,
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
              color: effective != null
                  ? (isOverride
                      ? const Color(0xFF1976D2)
                      : AppColors.foregroundPrimary)
                  : AppColors.foregroundTertiary,
            ),
          ),
        ),
      );
    }

    // Fallback: delegate to onCellTap
    return GestureDetector(
      onTap: () => widget.onCellTap?.call(participant, item, score),
      child: Container(
        width: GradeSpreadsheet._itemColWidth,
        height: GradeSpreadsheet._rowHeight,
        alignment: Alignment.center,
        decoration: border,
        child: Text(
          effective != null ? _formatScore(effective) : '--',
          style: TextStyle(
            fontSize: 12,
            color: effective != null
                ? AppColors.foregroundPrimary
                : AppColors.foregroundTertiary,
          ),
        ),
      ),
    );
  }

  Widget _inlineTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _cancelEdit,
        },
        child: TextField(
          controller: _editController,
          focusNode: _focusNode,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: const TextStyle(fontSize: 12),
          onSubmitted: (_) => _commitEdit(),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: Color(0xFF1976D2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: Color(0xFF1976D2),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: Color(0xFF1976D2),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
