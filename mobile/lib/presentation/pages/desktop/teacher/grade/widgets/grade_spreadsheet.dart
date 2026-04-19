import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';

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

  final void Function(
    String studentId,
    String itemId,
    GradeScore? existingScore,
    double newScore,
  ) onScoreChanged;

  final void Function(String studentId, int? currentQg) onQgChanged;

  const GradeSpreadsheet({
    super.key,
    required this.students,
    required this.allItems,
    required this.scoresByItem,
    required this.config,
    required this.summary,
    required this.onScoreChanged,
    required this.onQgChanged,
  });

  // Cell dimensions (desktop — wider than mobile)
  static const double nameColW = 180.0;
  static const double scoreColW = 68.0;
  static const double sumColW = 68.0;
  static const double pctColW = 72.0;
  static const double initGradeW = 80.0;
  static const double qgColW = 68.0;
  static const double remarksW = 96.0;
  static const double rowH = 44.0;
  static const double hdrH1 = 28.0;
  static const double hdrH2 = 40.0;

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

  // ── Score editing ────────────────────────────────────────────────────────

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
      _scoreCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _scoreCtrl.text.length));
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scoreFocus.requestFocus());
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
      _qgCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _qgCtrl.text.length));
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _qgFocus.requestFocus());
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

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  Map<String, Map<String, GradeScore>> _buildScoreLookup() {
    final lookup = <String, Map<String, GradeScore>>{};
    for (final entry in widget.scoresByItem.entries) {
      for (final score in entry.value) {
        lookup
            .putIfAbsent(score.studentId, () => {})[score.gradeItemId] = score;
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

  _Stats _computeStats(
    String studentId,
    List<GradeItem> items,
    Map<String, Map<String, GradeScore>> lookup,
    double weight,
  ) {
    final studentScores = lookup[studentId] ?? {};
    double total = 0;
    double hs = 0;
    bool hasScore = false;
    for (final item in items) {
      hs += item.totalPoints;
      final score = studentScores[item.id]?.effectiveScore;
      if (score != null) {
        total += score;
        hasScore = true;
      }
    }
    if (!hasScore || hs == 0) {
      return _Stats(total: null, hs: hs, pct: null, ws: null);
    }
    final pct = (total / hs) * 100;
    return _Stats(total: total, hs: hs, pct: pct, ws: pct * weight / 100);
  }

  double _secW(int n) =>
      n * GradeSpreadsheet.scoreColW +
      GradeSpreadsheet.sumColW * 2 +
      GradeSpreadsheet.pctColW * 2;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scoreLookup = _buildScoreLookup();
    final qgLookup = _buildQgLookup();

    final wwItems = widget.allItems
        .where((i) => i.component == 'ww')
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final ptItems = widget.allItems
        .where((i) => i.component == 'pt')
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final qaItems = widget.allItems
        .where((i) => i.component == 'qa')
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final wwW = widget.config?.wwWeight ?? 40.0;
    final ptW = widget.config?.ptWeight ?? 40.0;
    final qaW = widget.config?.qaWeight ?? 20.0;

    final wwSecW = _secW(wwItems.length);
    final ptSecW = _secW(ptItems.length);
    final qaSecW = _secW(qaItems.length);
    const summaryW =
        GradeSpreadsheet.initGradeW + GradeSpreadsheet.qgColW + GradeSpreadsheet.remarksW;
    final scrollW = wwSecW + ptSecW + qaSecW + summaryW;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Frozen name column ─────────────────────────────────────────
          SizedBox(
            width: GradeSpreadsheet.nameColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header row (blank)
                Container(
                  height: GradeSpreadsheet.hdrH1,
                  color: AppColors.backgroundTertiary,
                ),
                // Column header
                _hdrCell(
                  "Learner's Name",
                  GradeSpreadsheet.nameColW,
                  GradeSpreadsheet.hdrH2,
                  align: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                // HPS row — frozen side
                Container(
                  height: GradeSpreadsheet.rowH,
                  width: GradeSpreadsheet.nameColW,
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
                // Student name rows
                for (int i = 0; i < widget.students.length; i++) ...[
                  Container(
                    height: GradeSpreadsheet.rowH,
                    width: GradeSpreadsheet.nameColW,
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

          // Vertical separator
          Container(width: 1, color: AppColors.borderLight),

          // ── Scrollable columns ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: group headers
                    SizedBox(
                      height: GradeSpreadsheet.hdrH1,
                      child: Row(
                        children: [
                          _grpCell(
                              'WRITTEN WORKS (${wwW.toStringAsFixed(0)}%)',
                              wwSecW,
                              const Color(0xFFDEEBFF)),
                          _grpCell(
                              'PERFORMANCE TASKS (${ptW.toStringAsFixed(0)}%)',
                              ptSecW,
                              const Color(0xFFDCF5E4)),
                          _grpCell(
                              'QUARTERLY ASSESSMENT (${qaW.toStringAsFixed(0)}%)',
                              qaSecW,
                              const Color(0xFFFFF2D6)),
                          _grpCell('SUMMARY', summaryW, const Color(0xFFF0E6FF)),
                        ],
                      ),
                    ),
                    // Row 2: column sub-headers
                    SizedBox(
                      height: GradeSpreadsheet.hdrH2,
                      child: Row(
                        children: [
                          ..._sectionHdrs(wwItems),
                          ..._sectionHdrs(ptItems),
                          ..._sectionHdrs(qaItems),
                          _hdrCell('Initial Grade', GradeSpreadsheet.initGradeW,
                              GradeSpreadsheet.hdrH2),
                          _hdrCell(
                              'QG', GradeSpreadsheet.qgColW, GradeSpreadsheet.hdrH2),
                          _hdrCell('Remarks', GradeSpreadsheet.remarksW,
                              GradeSpreadsheet.hdrH2),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),

                    // HPS row — scrollable side
                    SizedBox(
                      height: GradeSpreadsheet.rowH,
                      child: Row(
                        children: [
                          ..._buildHpsSectionCells(wwItems, wwW),
                          ..._buildHpsSectionCells(ptItems, ptW),
                          ..._buildHpsSectionCells(qaItems, qaW),
                          _computedCell('--', GradeSpreadsheet.initGradeW, AppColors.backgroundTertiary),
                          _computedCell('--', GradeSpreadsheet.qgColW, AppColors.backgroundTertiary),
                          _computedCell('--', GradeSpreadsheet.remarksW, AppColors.backgroundTertiary),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),

                    // Data rows
                    for (int i = 0; i < widget.students.length; i++) ...[
                      _buildDataRow(
                        index: i,
                        participant: widget.students[i],
                        wwItems: wwItems,
                        ptItems: ptItems,
                        qaItems: qaItems,
                        scoreLookup: scoreLookup,
                        qgLookup: qgLookup,
                        wwW: wwW,
                        ptW: ptW,
                        qaW: qaW,
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
            child: _hdrCell('${i + 1}', GradeSpreadsheet.scoreColW,
                GradeSpreadsheet.hdrH2),
          ),
        _hdrCell(
            'Total', GradeSpreadsheet.sumColW, GradeSpreadsheet.hdrH2),
        _hdrCell('HS', GradeSpreadsheet.sumColW, GradeSpreadsheet.hdrH2),
        _hdrCell('%', GradeSpreadsheet.pctColW, GradeSpreadsheet.hdrH2),
        _hdrCell('WS', GradeSpreadsheet.pctColW, GradeSpreadsheet.hdrH2),
      ];

  List<Widget> _buildHpsSectionCells(List<GradeItem> items, double weight) {
    final hs = items.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
    return [
      for (final item in items)
        _computedCell(_fmt(item.totalPoints), GradeSpreadsheet.scoreColW,
            AppColors.backgroundTertiary,
            bold: true),
      _computedCell(items.isNotEmpty ? _fmt(hs) : '--',
          GradeSpreadsheet.sumColW, AppColors.backgroundTertiary,
          bold: true),
      _computedCell(items.isNotEmpty ? _fmt(hs) : '--',
          GradeSpreadsheet.sumColW, AppColors.backgroundTertiary,
          bold: true),
      _computedCell(items.isNotEmpty ? '100%' : '--',
          GradeSpreadsheet.pctColW, AppColors.backgroundTertiary),
      _computedCell(
          items.isNotEmpty ? '${weight.toStringAsFixed(0)}%' : '--',
          GradeSpreadsheet.pctColW,
          AppColors.backgroundTertiary,
          bold: true),
    ];
  }

  Widget _buildDataRow({
    required int index,
    required Participant participant,
    required List<GradeItem> wwItems,
    required List<GradeItem> ptItems,
    required List<GradeItem> qaItems,
    required Map<String, Map<String, GradeScore>> scoreLookup,
    required Map<String, int?> qgLookup,
    required double wwW,
    required double ptW,
    required double qaW,
  }) {
    final sid = participant.student.id;
    final bgColor = index.isEven
        ? AppColors.backgroundPrimary
        : AppColors.backgroundTertiary;

    final wwStats = _computeStats(sid, wwItems, scoreLookup, wwW);
    final ptStats = _computeStats(sid, ptItems, scoreLookup, ptW);
    final qaStats = _computeStats(sid, qaItems, scoreLookup, qaW);

    final parts = [wwStats.ws, ptStats.ws, qaStats.ws];
    final available = parts.whereType<double>().toList();
    final double? initialGrade = available.isNotEmpty
        ? available.fold<double>(0.0, (sum, v) => sum + v)
        : null;

    final storedQg = qgLookup[sid];
    final computedQg = initialGrade != null
        ? TransmutationUtil.transmute(initialGrade).round()
        : null;
    final displayQg = storedQg ?? computedQg;
    final remarks =
        displayQg != null ? (displayQg >= 75 ? 'Passed' : 'Failed') : null;
    final isEditingQg = _editingQgStudentId == sid;

    return SizedBox(
      height: GradeSpreadsheet.rowH,
      child: Row(
        children: [
          ..._sectionCells(
              participant, wwItems, scoreLookup, wwStats, bgColor),
          ..._sectionCells(
              participant, ptItems, scoreLookup, ptStats, bgColor),
          ..._sectionCells(
              participant, qaItems, scoreLookup, qaStats, bgColor),
          // Initial grade
          _computedCell(
            initialGrade != null ? _fmt(initialGrade) : '--',
            GradeSpreadsheet.initGradeW,
            bgColor,
            bold: true,
          ),
          // QG (inline-editable)
          if (isEditingQg)
            _inlineCell(_qgCtrl, _qgFocus, _commitQg, _cancelQg,
                GradeSpreadsheet.qgColW, bgColor)
          else
            GestureDetector(
              onTap: () => _startQg(sid, displayQg),
              child: _computedCell(
                displayQg?.toString() ?? '--',
                GradeSpreadsheet.qgColW,
                bgColor,
                bold: true,
                color: storedQg != null
                    ? const Color(0xFF1565C0)
                    : (displayQg != null ? AppColors.foregroundPrimary : null),
              ),
            ),
          // Remarks
          _remarksCell(remarks, bgColor),
        ],
      ),
    );
  }

  List<Widget> _sectionCells(
    Participant participant,
    List<GradeItem> items,
    Map<String, Map<String, GradeScore>> scoreLookup,
    _Stats stats,
    Color bgColor,
  ) {
    final sid = participant.student.id;
    final studentScores = scoreLookup[sid] ?? {};

    return [
      for (final item in items) ...[
        () {
          final gs = studentScores[item.id];
          final cellKey = '${sid}_${item.id}';
          final isEditing = _editingKey == cellKey;
          final isOverride = gs?.overrideScore != null;
          final displayScore = gs?.effectiveScore;

          if (isEditing) {
            return _inlineCell(_scoreCtrl, _scoreFocus, _commitScore,
                _clearScore, GradeSpreadsheet.scoreColW, bgColor);
          }
          return GestureDetector(
            onTap: () => _startScore(sid, item.id, gs),
            child: _scoreCell(
              displayScore != null ? _fmt(displayScore) : '--',
              GradeSpreadsheet.scoreColW,
              bgColor,
              isOverride: isOverride,
              empty: displayScore == null,
            ),
          );
        }(),
      ],
      _computedCell(
          stats.total != null ? _fmt(stats.total!) : '--',
          GradeSpreadsheet.sumColW,
          bgColor),
      _computedCell(
          items.isNotEmpty ? _fmt(stats.hs) : '--',
          GradeSpreadsheet.sumColW,
          bgColor),
      _computedCell(
          stats.pct != null ? '${stats.pct!.toStringAsFixed(1)}%' : '--',
          GradeSpreadsheet.pctColW,
          bgColor),
      _computedCell(
          stats.ws != null ? _fmt(stats.ws!) : '--',
          GradeSpreadsheet.pctColW,
          bgColor,
          bold: true),
    ];
  }

  // ── Cell builders ─────────────────────────────────────────────────────────

  Widget _grpCell(String label, double width, Color color) {
    return Container(
      width: width,
      height: GradeSpreadsheet.hdrH1,
      color: color,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444444)),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _hdrCell(
    String text,
    double width,
    double height, {
    Alignment align = Alignment.center,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 6),
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: const BoxDecoration(
        color: AppColors.backgroundTertiary,
        border: Border(
          right: BorderSide(color: AppColors.borderLight, width: 0.5),
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      alignment: align,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundSecondary),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _scoreCell(
    String text,
    double width,
    Color bgColor, {
    bool isOverride = false,
    bool empty = false,
  }) {
    return Container(
      width: width,
      height: GradeSpreadsheet.rowH,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
            right: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
          color: isOverride
              ? const Color(0xFF1565C0)
              : (empty
                  ? AppColors.foregroundTertiary
                  : AppColors.foregroundPrimary),
        ),
      ),
    );
  }

  Widget _computedCell(
    String text,
    double width,
    Color bgColor, {
    bool bold = false,
    Color? color,
  }) {
    return Container(
      width: width,
      height: GradeSpreadsheet.rowH,
      decoration: const BoxDecoration(
        color: AppColors.backgroundTertiary,
        border: Border(
            right: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color ??
              (text == '--'
                  ? AppColors.foregroundTertiary
                  : AppColors.foregroundSecondary),
        ),
      ),
    );
  }

  Widget _remarksCell(String? remarks, Color bgColor) {
    if (remarks == null) {
      return _computedCell('--', GradeSpreadsheet.remarksW, bgColor);
    }
    final passed = remarks == 'Passed';
    return Container(
      width: GradeSpreadsheet.remarksW,
      height: GradeSpreadsheet.rowH,
      color: AppColors.backgroundTertiary,
      alignment: Alignment.center,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: passed
              ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
              : const Color(0xFFE57373).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          remarks,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: passed
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
          ),
        ),
      ),
    );
  }

  Widget _inlineCell(
    TextEditingController ctrl,
    FocusNode focus,
    VoidCallback onCommit,
    VoidCallback onCancel,
    double width,
    Color bgColor,
  ) {
    return SizedBox(
      width: width,
      height: GradeSpreadsheet.rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): onCancel,
          },
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => onCommit(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                    color: Color(0xFF1976D2), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                    color: Color(0xFF1976D2), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                    color: Color(0xFF1976D2), width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal helper ───────────────────────────────────────────────────────────

class _Stats {
  final double? total;
  final double hs;
  final double? pct;
  final double? ws;

  const _Stats({
    required this.total,
    required this.hs,
    required this.pct,
    required this.ws,
  });
}
