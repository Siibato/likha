import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_data_row.dart';
import 'package:likha/presentation/widgets/shared/teacher/grade/grade_spreadsheet_cells.dart';

/// DepEd-style Class Record spreadsheet.
///
/// Displays all three grade components (WW, PT, QA) side-by-side in a single
/// horizontally-scrollable sheet, matching the official DepEd Class Record
/// format. Computed columns (Total, HS, %, WS, Initial Grade, Remarks) are
/// derived on the fly from the provided items and scores.
///
/// Pass [dimensions] to control column widths:
/// - [GradeSpreadsheetDimensions.standard] for desktop (wide)
/// - [GradeSpreadsheetDimensions.compact] for mobile (narrow)
class GradeSpreadsheet extends StatefulWidget {
  final List<Participant> students;

  /// All grade items for the selected term (all components combined).
  final List<GradeItem> allItems;

  final Map<String, List<GradeScore>> scoresByItem;
  final GradeConfig? config;

  /// Per-student term grade summary rows from the server.
  /// Each map contains at minimum: 'student_id' and 'transmuted_grade'.
  final List<Map<String, dynamic>>? summary;

  /// When true, score cells render as pulsing skeletons and are non-tappable.
  final bool isLoadingScores;

  /// Column/row size preset — use [GradeSpreadsheetDimensions.standard] for
  /// desktop and [GradeSpreadsheetDimensions.compact] for mobile.
  final GradeSpreadsheetDimensions dimensions;

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
    required this.dimensions,
    this.isLoadingScores = false,
    required this.onScoreChanged,
    required this.onQgChanged,
    required this.onAddColumn,
  });

  @override
  State<GradeSpreadsheet> createState() => _GradeSpreadsheetState();
}

class _GradeSpreadsheetState extends State<GradeSpreadsheet> {
  String? _editingKey;
  String? _editingStudentId;
  String? _editingItemId;
  GradeScore? _editingExistingScore;
  final _scoreCtrl = TextEditingController();
  final _scoreFocus = FocusNode();

  String? _editingQgStudentId;
  final _tgCtrl = TextEditingController();
  final _tgFocus = FocusNode();

  final _horizontalScrollCtrl = ScrollController();

  final _verticalScrollCtrl = ScrollController();

  bool _isPanning = false;

  GradeSpreadsheetDimensions get _d => widget.dimensions;

  @override
  void initState() {
    super.initState();
    _scoreFocus.addListener(() {
      if (!_scoreFocus.hasFocus && _editingKey != null) _commitScore();
    });
    _tgFocus.addListener(() {
      if (!_tgFocus.hasFocus && _editingQgStudentId != null) _commitQg();
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _scoreFocus.dispose();
    _tgCtrl.dispose();
    _tgFocus.dispose();
    _horizontalScrollCtrl.dispose();
    _verticalScrollCtrl.dispose();
    super.dispose();
  }

  // ── Score editing ──────────────────────────────────────────────────────────

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

  // ── QG editing ─────────────────────────────────────────────────────────────

  void _startQg(String studentId, int? current) {
    if (_editingKey != null) _commitScore();
    if (_editingQgStudentId != null) _commitQg();
    setState(() {
      _editingQgStudentId = studentId;
      _tgCtrl.text = current?.toString() ?? '';
      _tgCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _tgCtrl.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _tgFocus.requestFocus());
  }

  void _commitQg() {
    final grade = int.tryParse(_tgCtrl.text.trim());
    if (grade != null && _editingQgStudentId != null) {
      widget.onQgChanged(_editingQgStudentId!, grade);
    }
    if (mounted) setState(() => _editingQgStudentId = null);
  }

  void _cancelQg() {
    if (mounted) setState(() => _editingQgStudentId = null);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Map<String, Map<String, GradeScore>> _buildScoreLookup() {
    final lookup = <String, Map<String, GradeScore>>{};
    for (final entry in widget.scoresByItem.entries) {
      for (final score in entry.value) {
        lookup.putIfAbsent(score.studentId, () => {})[score.gradeItemId] = score;
      }
    }
    return lookup;
  }

  Map<String, int?> _buildTransmutedGradeLookup() {
    final lookup = <String, int?>{};
    for (final row in (widget.summary ?? [])) {
      final sid = row['student_id'] as String?;
      final tg = row['transmuted_grade'];
      if (sid != null) {
        lookup[sid] = tg == null
            ? null
            : (tg is double
                ? tg.round()
                : (tg is int ? tg : int.tryParse(tg.toString())));
      }
    }
    return lookup;
  }

  double _secW(int n) =>
      n * _d.scoreColW + _d.sumColW * 2 + _d.pctColW * 2;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scoreLookup = _buildScoreLookup();
    final tgLookup = _buildTransmutedGradeLookup();

    final wwItems = widget.allItems.where((i) => i.component == 'ww' || i.component == 'written_work').toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final ptItems = widget.allItems.where((i) => i.component == 'pt' || i.component == 'performance_task').toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final qaItems = widget.allItems.where((i) => i.component == 'qa' || i.component == 'term_assessment').toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final wwW = widget.config?.wwWeight ?? 40.0;
    final ptW = widget.config?.ptWeight ?? 40.0;
    final qaW = widget.config?.qaWeight ?? 20.0;

    final wwSecW = _secW(wwItems.length);
    final ptSecW = _secW(ptItems.length);
    final qaSecW = _secW(qaItems.length);
    final summaryW = _d.initGradeW + _d.qgColW + _d.remarksW;
    final scrollW = wwSecW + ptSecW + qaSecW + summaryW;

    final isDesktopOrWeb = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        kIsWeb;

    Widget spreadsheet = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Frozen name column ─────────────────────────────────────────────
          SizedBox(
            width: _d.nameColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: _d.hdrH1,
                  color: AppColors.backgroundTertiary,
                ),
                GradeColumnHeaderCell(
                  text: "Learner's Name",
                  width: _d.nameColW,
                  height: _d.hdrH2,
                  align: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                Container(
                  height: _d.rowH,
                  width: _d.nameColW,
                  color: AppColors.backgroundTertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'HIGHEST POSSIBLE SCORE',
                    style: TextStyle(
                      fontSize: 9,
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
                    height: _d.rowH,
                    width: _d.nameColW,
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

          // ── Scrollable columns ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group header row
                    SizedBox(
                      height: _d.hdrH1,
                      child: Row(
                        children: [
                          GradeGroupHeaderCell(
                            label: 'WRITTEN WORKS (${wwW.toStringAsFixed(0)}%)',
                            width: wwSecW,
                            height: _d.hdrH1,
                            color: AppColors.accentCharcoal.withValues(alpha: 0.1),
                          ),
                          GradeGroupHeaderCell(
                            label: 'PERFORMANCE TASKS (${ptW.toStringAsFixed(0)}%)',
                            width: ptSecW,
                            height: _d.hdrH1,
                            color: AppColors.semanticSuccessAlt.withValues(alpha: 0.1),
                          ),
                          GradeGroupHeaderCell(
                            label:
                                'TERM ASSESSMENT (${qaW.toStringAsFixed(0)}%)',
                            width: qaSecW,
                            height: _d.hdrH1,
                            color: AppColors.accentAmber.withValues(alpha: 0.1),
                          ),
                          GradeGroupHeaderCell(
                            label: 'SUMMARY',
                            width: summaryW,
                            height: _d.hdrH1,
                            color: AppColors.accentAmber.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ),
                    // Column sub-header row
                    SizedBox(
                      height: _d.hdrH2,
                      child: Row(
                        children: [
                          ..._sectionHdrs(wwItems),
                          ..._sectionHdrs(ptItems),
                          ..._sectionHdrs(qaItems),
                          GradeColumnHeaderCell(
                            text: 'Initial Grade',
                            width: _d.initGradeW,
                            height: _d.hdrH2,
                          ),
                          GradeColumnHeaderCell(
                            text: 'TG',
                            width: _d.qgColW,
                            height: _d.hdrH2,
                          ),
                          GradeColumnHeaderCell(
                            text: 'Remarks',
                            width: _d.remarksW,
                            height: _d.hdrH2,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    // HPS row
                    SizedBox(
                      height: _d.rowH,
                      child: Row(
                        children: [
                          ..._buildHpsCells(wwItems, wwW),
                          ..._buildHpsCells(ptItems, ptW),
                          ..._buildHpsCells(qaItems, qaW),
                          GradeComputedCell(
                              text: '--',
                              width: _d.initGradeW,
                              height: _d.rowH),
                          GradeComputedCell(
                              text: '--', width: _d.qgColW, height: _d.rowH),
                          GradeComputedCell(
                              text: '--',
                              width: _d.remarksW,
                              height: _d.rowH),
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
                        tgLookup: tgLookup,
                        wwWeight: wwW,
                        ptWeight: ptW,
                        qaWeight: qaW,
                        isLoadingScores: widget.isLoadingScores,
                        dimensions: _d,
                        editingKey: _editingKey,
                        editingQgStudentId: _editingQgStudentId,
                        scoreCtrl: _scoreCtrl,
                        scoreFocus: _scoreFocus,
                        tgCtrl: _tgCtrl,
                        tgFocus: _tgFocus,
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
      );

    if (isDesktopOrWeb) {
      spreadsheet = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {
          if (_editingKey != null || _editingQgStudentId != null) return;
          setState(() => _isPanning = true);
        },
        onPanUpdate: (details) {
          if (_editingKey != null || _editingQgStudentId != null) return;
          if (_horizontalScrollCtrl.hasClients) {
            final newOffset = (_horizontalScrollCtrl.offset - details.delta.dx).clamp(
              _horizontalScrollCtrl.position.minScrollExtent,
              _horizontalScrollCtrl.position.maxScrollExtent,
            );
            _horizontalScrollCtrl.jumpTo(newOffset);
          }
          if (_verticalScrollCtrl.hasClients) {
            final newOffset = (_verticalScrollCtrl.offset - details.delta.dy).clamp(
              _verticalScrollCtrl.position.minScrollExtent,
              _verticalScrollCtrl.position.maxScrollExtent,
            );
            _verticalScrollCtrl.jumpTo(newOffset);
          }
        },
        onPanEnd: (_) {
          if (_isPanning) setState(() => _isPanning = false);
        },
        onPanCancel: () {
          if (_isPanning) setState(() => _isPanning = false);
        },
        child: spreadsheet,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth - _d.nameColW - 1;
        return Column(
          children: [
            Expanded(
              child: RawScrollbar(
                controller: _verticalScrollCtrl,
                thumbVisibility: true,
                thickness: 12,
                radius: const Radius.circular(6),
                thumbColor: Colors.grey.withValues(alpha: 0.45),
                trackColor: Colors.transparent,
                child: SingleChildScrollView(
                  controller: _verticalScrollCtrl,
                  child: spreadsheet,
                ),
              ),
            ),
            if (scrollW > viewportW)
              Row(
                children: [
                  SizedBox(width: _d.nameColW + 1),
                  Expanded(
                    child: _HorizontalScrollbar(
                      controller: _horizontalScrollCtrl,
                      contentWidth: scrollW,
                      viewportWidth: viewportW,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  List<Widget> _sectionHdrs(List<GradeItem> items) => [
        for (int i = 0; i < items.length; i++)
          Tooltip(
            message: items[i].title,
            child: GradeColumnHeaderCell(
              text: '${i + 1}',
              width: _d.scoreColW,
              height: _d.hdrH2,
            ),
          ),
        GradeColumnHeaderCell(
            text: 'Total', width: _d.sumColW, height: _d.hdrH2),
        GradeColumnHeaderCell(
            text: 'HS', width: _d.sumColW, height: _d.hdrH2),
        GradeColumnHeaderCell(
            text: '%', width: _d.pctColW, height: _d.hdrH2),
        GradeColumnHeaderCell(
            text: 'WS', width: _d.pctColW, height: _d.hdrH2),
      ];

  List<Widget> _buildHpsCells(List<GradeItem> items, double weight) {
    final hs = items.fold<double>(0.0, (sum, item) => sum + item.totalPoints);
    return [
      for (final item in items)
        GradeComputedCell(
          text: _fmt(item.totalPoints),
          width: _d.scoreColW,
          height: _d.rowH,
          bold: true,
        ),
      GradeComputedCell(
        text: items.isNotEmpty ? _fmt(hs) : '--',
        width: _d.sumColW,
        height: _d.rowH,
        bold: true,
      ),
      GradeComputedCell(
        text: items.isNotEmpty ? _fmt(hs) : '--',
        width: _d.sumColW,
        height: _d.rowH,
        bold: true,
      ),
      GradeComputedCell(
        text: items.isNotEmpty ? '100%' : '--',
        width: _d.pctColW,
        height: _d.rowH,
      ),
      GradeComputedCell(
        text: items.isNotEmpty ? '${weight.toStringAsFixed(0)}%' : '--',
        width: _d.pctColW,
        height: _d.rowH,
        bold: true,
      ),
    ];
  }
}

/// A simple custom horizontal scrollbar track + thumb that's always visible.
class _HorizontalScrollbar extends StatefulWidget {
  final ScrollController controller;
  final double contentWidth;
  final double viewportWidth;

  const _HorizontalScrollbar({
    required this.controller,
    required this.contentWidth,
    required this.viewportWidth,
  });

  @override
  State<_HorizontalScrollbar> createState() => _HorizontalScrollbarState();
}

class _HorizontalScrollbarState extends State<_HorizontalScrollbar> {
  double _thumbLeft = 0;
  double _thumbWidth = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateThumb());
  }

  @override
  void didUpdateWidget(covariant _HorizontalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportWidth != widget.viewportWidth ||
        oldWidget.contentWidth != widget.contentWidth) {
      _updateThumb();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => _updateThumb();

  void _updateThumb() {
    if (!mounted) return;
    final maxScroll = widget.controller.position.maxScrollExtent;
    final current = widget.controller.offset;
    final ratio = maxScroll > 0 ? current / maxScroll : 0;
    final thumbW = (widget.viewportWidth / widget.contentWidth).clamp(0.05, 1.0) * widget.viewportWidth;
    final maxThumbLeft = widget.viewportWidth - thumbW;
    final left = ratio * maxThumbLeft;
    setState(() {
      _thumbLeft = left;
      _thumbWidth = thumbW;
    });
  }

  void _onTrackTap(double localDx) {
    final thumbCenter = _thumbLeft + _thumbWidth / 2;
    final maxScroll = widget.controller.position.maxScrollExtent;
    if (localDx > thumbCenter) {
      widget.controller.jumpTo((widget.controller.offset + widget.viewportWidth * 0.8).clamp(0.0, maxScroll));
    } else {
      widget.controller.jumpTo((widget.controller.offset - widget.viewportWidth * 0.8).clamp(0.0, maxScroll));
    }
  }

  void _onThumbDrag(double delta) {
    final maxScroll = widget.controller.position.maxScrollExtent;
    final maxThumbLeft = widget.viewportWidth - _thumbWidth;
    final scrollDelta = maxScroll > 0 && maxThumbLeft > 0
        ? delta * maxScroll / maxThumbLeft
        : 0.0;
    widget.controller.jumpTo((widget.controller.offset + scrollDelta).clamp(0.0, maxScroll));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) => _onTrackTap(details.localPosition.dx),
      child: Container(
        height: 12,
        color: Colors.transparent,
        child: Stack(
          children: [
            // Subtle track line
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: _thumbLeft,
              top: 2,
              bottom: 2,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) => _onThumbDrag(details.delta.dx),
                child: Container(
                  width: _thumbWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
