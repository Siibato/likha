import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/grade_data_row.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/grade_spreadsheet_cells.dart';

/// DepEd-style Class Record spreadsheet.
///
/// Displays all three grade components (WW, PT, QA) side-by-side in a single
/// horizontally-scrollable sheet, matching the official DepEd Class Record
/// format. Computed columns (Total, HS, %, WS, Initial Grade, Remarks) are
/// derived on the fly from the provided items and scores.
class GradeSpreadsheet extends StatefulWidget {
  final List<Participant> students;

  /// All grade items for the selected quarter (all components combined).
  final List<GradeItem> allItems;

  final Map<String, List<GradeScore>> scoresByItem;
  final GradeConfig? config;

  /// Per-student quarterly grade summary rows from the server.
  /// Each map contains at minimum: 'student_id' and 'quarterly_grade'.
  final List<Map<String, dynamic>>? summary;

  /// When true, score cells render as pulsing skeletons and are non-tappable.
  final bool isLoadingScores;

  final void Function(
    String studentId,
    String itemId,
    GradeScore? existingScore,
    double newScore,
  ) onScoreChanged;

  final void Function(String studentId, int? currentQg) onQgChanged;

  /// Called when the teacher taps the '+' button in a section header.
  /// [component] is 'ww', 'pt', or 'qa'.
  final void Function(String component) onAddColumn;

  const GradeSpreadsheet({
    super.key,
    required this.students,
    required this.allItems,
    required this.scoresByItem,
    required this.config,
    required this.summary,
    this.isLoadingScores = false,
    required this.onScoreChanged,
    required this.onQgChanged,
    required this.onAddColumn,
  });

  @override
  State<GradeSpreadsheet> createState() => _GradeSpreadsheetState();
}

class _GradeSpreadsheetState extends State<GradeSpreadsheet> {
  // Score inline editing
  String? _editingKey;
  String? _editingStudentId;
  String? _editingItemId;
  GradeScore? _editingExistingScore;
  final _scoreCtrl = TextEditingController();
  final _scoreFocus = FocusNode();

  // QG inline editing
  String? _editingQgStudentId;
  final _qgCtrl = TextEditingController();
  final _qgFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _scoreFocus.addListener(() {
      if (!_scoreFocus.hasFocus && _editingKey != null) _commitScore();
    });
    _qgFocus.addListener(() {
      if (!_qgFocus.hasFocus && _editingQgStudentId != null) _commitQg();
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _scoreFocus.dispose();
    _qgCtrl.dispose();
    _qgFocus.dispose();
    super.dispose();
  }

  // ── Score editing ─────────────────────────────────────────────────────────

  void _startScore(String studentId, String itemId, GradeScore? existing) {
    if (_editingKey != null) _commitScore();
    if (_editingQgStudentId != null) _commitQg();
    final current = existing?.effectiveScore;
    setState(() {
      _editingKey = '${studentId}_$itemId';
      _editingStudentId = studentId;
      _editingItemId = itemId;
      _editingExistingScore = existing;
      _scoreCtrl.text = current != null ? _fmt(current) : '';
      _scoreCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _scoreCtrl.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scoreFocus.requestFocus());
  }

  void _commitScore() {
    final score = double.tryParse(_scoreCtrl.text.trim());
    if (score != null && _editingStudentId != null && _editingItemId != null) {
      widget.onScoreChanged(
          _editingStudentId!, _editingItemId!, _editingExistingScore, score);
    }
    _clearScore();
  }

  void _clearScore() {
    if (!mounted) return;
    setState(() {
      _editingKey = null;
      _editingStudentId = null;
      _editingItemId = null;
      _editingExistingScore = null;
    });
  }

  // ── QG editing ────────────────────────────────────────────────────────────

  void _startQg(String studentId, int? current) {
    if (_editingKey != null) _commitScore();
    if (_editingQgStudentId != null) _commitQg();
    setState(() {
      _editingQgStudentId = studentId;
      _qgCtrl.text = current?.toString() ?? '';
      _qgCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _qgCtrl.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _qgFocus.requestFocus());
  }

  void _commitQg() {
    final grade = int.tryParse(_qgCtrl.text.trim());
    if (grade != null && _editingQgStudentId != null) {
      widget.onQgChanged(_editingQgStudentId!, grade);
    }
    if (mounted) setState(() => _editingQgStudentId = null);
  }

  void _cancelQg() {
    if (mounted) setState(() => _editingQgStudentId = null);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Map<String, Map<String, GradeScore>> _buildScoreLookup() {
    final lookup = <String, Map<String, GradeScore>>{};
    for (final entry in widget.scoresByItem.entries) {
      for (final score in entry.value) {
        lookup.putIfAbsent(score.studentId, () => {})[score.gradeItemId] = score;
      }
    }
    return lookup;
  }

  Map<String, int?> _buildQgLookup() {
    final lookup = <String, int?>{};
    for (final row in (widget.summary ?? [])) {
      final sid = row['student_id'] as String?;
      final qg = row['quarterly_grade'];
      if (sid != null) {
        lookup[sid] = qg == null
            ? null
            : (qg is double
                ? qg.round()
                : (qg is int ? qg : int.tryParse(qg.toString())));
      }
    }
    return lookup;
  }

  // Section width = N score columns + Total + HS + % + WS
  double _secW(int n) =>
      n * GradeSpreadsheetDimensions.scoreColW +
      GradeSpreadsheetDimensions.sumColW * 2 +
      GradeSpreadsheetDimensions.pctColW * 2;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scoreLookup = _buildScoreLookup();
    final qgLookup = _buildQgLookup();

    final wwItems = widget.allItems.where((i) => i.component == 'ww').toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final ptItems = widget.allItems.where((i) => i.component == 'pt').toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final qaItems = widget.allItems.where((i) => i.component == 'qa').toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final wwW = widget.config?.wwWeight ?? 40.0;
    final ptW = widget.config?.ptWeight ?? 40.0;
    final qaW = widget.config?.qaWeight ?? 20.0;

    final wwSecW = _secW(wwItems.length);
    final ptSecW = _secW(ptItems.length);
    final qaSecW = _secW(qaItems.length);
    const summaryW = GradeSpreadsheetDimensions.initGradeW +
        GradeSpreadsheetDimensions.qgColW +
        GradeSpreadsheetDimensions.remarksW;
    final scrollW = wwSecW + ptSecW + qaSecW + summaryW;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Frozen name column ───────────────────────────────────────────
          SizedBox(
            width: GradeSpreadsheetDimensions.nameColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: GradeSpreadsheetDimensions.hdrH1,
                  color: AppColors.backgroundTertiary,
                ),
                GradeColumnHeaderCell(
                  text: "Learner's Name",
                  width: GradeSpreadsheetDimensions.nameColW,
                  height: GradeSpreadsheetDimensions.hdrH2,
                  align: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                Container(
                  height: GradeSpreadsheetDimensions.rowH,
                  width: GradeSpreadsheetDimensions.nameColW,
                  color: AppColors.backgroundTertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'HIGHEST POSSIBLE SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                for (int i = 0; i < widget.students.length; i++) ...[
                  Container(
                    height: GradeSpreadsheetDimensions.rowH,
                    width: GradeSpreadsheetDimensions.nameColW,
                    color: i.isEven
                        ? AppColors.backgroundPrimary
                        : AppColors.backgroundTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${i + 1}. ${widget.students[i].student.fullName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foregroundPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (i < widget.students.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              ],
            ),
          ),

          Container(width: 1, color: AppColors.borderLight),

          // ── Scrollable columns ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group header row
                    SizedBox(
                      height: GradeSpreadsheetDimensions.hdrH1,
                      child: Row(
                        children: [
                          GradeGroupHeaderCell(
                            label: 'WRITTEN WORKS (${wwW.toStringAsFixed(0)}%)',
                            width: wwSecW,
                            color: AppColors.accentCharcoal.withValues(alpha: 0.1),
                          ),
                          GradeGroupHeaderCell(
                            label:
                                'PERFORMANCE TASKS (${ptW.toStringAsFixed(0)}%)',
                            width: ptSecW,
                            color: AppColors.semanticSuccessAlt.withValues(alpha: 0.1),
                          ),
                          GradeGroupHeaderCell(
                            label:
                                'QUARTERLY ASSESSMENT (${qaW.toStringAsFixed(0)}%)',
                            width: qaSecW,
                            color: AppColors.accentAmber.withValues(alpha: 0.1),
                          ),
                          GradeGroupHeaderCell(
                            label: 'SUMMARY',
                            width: summaryW,
                            color: AppColors.accentAmber.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ),
                    // Column sub-header row
                    SizedBox(
                      height: GradeSpreadsheetDimensions.hdrH2,
                      child: Row(
                        children: [
                          ..._sectionHdrs(wwItems),
                          ..._sectionHdrs(ptItems),
                          ..._sectionHdrs(qaItems),
                          GradeColumnHeaderCell(
                            text: 'Initial Grade',
                            width: GradeSpreadsheetDimensions.initGradeW,
                            height: GradeSpreadsheetDimensions.hdrH2,
                          ),
                          GradeColumnHeaderCell(
                            text: 'QG',
                            width: GradeSpreadsheetDimensions.qgColW,
                            height: GradeSpreadsheetDimensions.hdrH2,
                          ),
                          GradeColumnHeaderCell(
                            text: 'Remarks',
                            width: GradeSpreadsheetDimensions.remarksW,
                            height: GradeSpreadsheetDimensions.hdrH2,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    // HPS row
                    SizedBox(
                      height: GradeSpreadsheetDimensions.rowH,
                      child: Row(
                        children: [
                          ..._buildHpsCells(wwItems, wwW),
                          ..._buildHpsCells(ptItems, ptW),
                          ..._buildHpsCells(qaItems, qaW),
                          GradeComputedCell(text: '--', width: GradeSpreadsheetDimensions.initGradeW),
                          GradeComputedCell(text: '--', width: GradeSpreadsheetDimensions.qgColW),
                          GradeComputedCell(text: '--', width: GradeSpreadsheetDimensions.remarksW),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    // Data rows
                    for (int i = 0; i < widget.students.length; i++) ...[
                      GradeDataRow(
                        index: i,
                        participant: widget.students[i],
                        wwItems: wwItems,
                        ptItems: ptItems,
                        qaItems: qaItems,
                        scoreLookup: scoreLookup,
                        qgLookup: qgLookup,
                        wwWeight: wwW,
                        ptWeight: ptW,
                        qaWeight: qaW,
                        isLoadingScores: widget.isLoadingScores,
                        editingKey: _editingKey,
                        editingQgStudentId: _editingQgStudentId,
                        scoreCtrl: _scoreCtrl,
                        scoreFocus: _scoreFocus,
                        qgCtrl: _qgCtrl,
                        qgFocus: _qgFocus,
                        onStartScore: _startScore,
                        onCommitScore: _commitScore,
                        onClearScore: _clearScore,
                        onStartQg: _startQg,
                        onCommitQg: _commitQg,
                        onCancelQg: _cancelQg,
                      ),
                      if (i < widget.students.length - 1)
                        const Divider(height: 1, color: AppColors.borderLight),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sectionHdrs(List<GradeItem> items) => [
        for (int i = 0; i < items.length; i++)
          Tooltip(
            message: items[i].title,
            child: GradeColumnHeaderCell(
              text: '${i + 1}',
              width: GradeSpreadsheetDimensions.scoreColW,
              height: GradeSpreadsheetDimensions.hdrH2,
            ),
          ),
        GradeColumnHeaderCell(
          text: 'Total',
          width: GradeSpreadsheetDimensions.sumColW,
          height: GradeSpreadsheetDimensions.hdrH2,
        ),
        GradeColumnHeaderCell(
          text: 'HS',
          width: GradeSpreadsheetDimensions.sumColW,
          height: GradeSpreadsheetDimensions.hdrH2,
        ),
        GradeColumnHeaderCell(
          text: '%',
          width: GradeSpreadsheetDimensions.pctColW,
          height: GradeSpreadsheetDimensions.hdrH2,
        ),
        GradeColumnHeaderCell(
          text: 'WS',
          width: GradeSpreadsheetDimensions.pctColW,
          height: GradeSpreadsheetDimensions.hdrH2,
        ),
      ];

  List<Widget> _buildHpsCells(List<GradeItem> items, double weight) {
    final hs = items.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
    return [
      for (final item in items)
        GradeComputedCell(
          text: _fmt(item.totalPoints),
          width: GradeSpreadsheetDimensions.scoreColW,
          bold: true,
        ),
      GradeComputedCell(
        text: items.isNotEmpty ? _fmt(hs) : '--',
        width: GradeSpreadsheetDimensions.sumColW,
        bold: true,
      ),
      GradeComputedCell(
        text: items.isNotEmpty ? _fmt(hs) : '--',
        width: GradeSpreadsheetDimensions.sumColW,
        bold: true,
      ),
      GradeComputedCell(
        text: items.isNotEmpty ? '100%' : '--',
        width: GradeSpreadsheetDimensions.pctColW,
      ),
      GradeComputedCell(
        text: items.isNotEmpty ? '${weight.toStringAsFixed(0)}%' : '--',
        width: GradeSpreadsheetDimensions.pctColW,
        bold: true,
      ),
    ];
  }
}
