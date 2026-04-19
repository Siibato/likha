import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/grade/widgets/add_grade_item_dialog.dart';
import 'package:likha/presentation/pages/teacher/grade/widgets/quarter_selector.dart';
import 'package:likha/presentation/pages/teacher/class/class_grading_setup_page.dart';
import 'package:likha/presentation/pages/teacher/grade/grade_summary_page.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class ClassRecordPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassRecordPage({super.key, required this.classId});

  @override
  ConsumerState<ClassRecordPage> createState() => _ClassRecordPageState();
}

class _ClassRecordPageState extends ConsumerState<ClassRecordPage> {
  int _selectedQuarter = 1;
  bool _initialCheckDone = false;

  // Score inline editing
  String? _editingKey; // "${studentId}_${itemId}"
  String? _editingStudentId;
  String? _editingItemId;
  GradeScore? _editingExistingScore;
  final _scoreCtrl = TextEditingController();
  final _scoreFocus = FocusNode();

  // QG inline editing
  String? _editingQgStudentId;
  final _qgCtrl = TextEditingController();
  final _qgFocus = FocusNode();

  // Cell dimensions
  static const double _nameColW = 130.0;
  static const double _scoreColW = 52.0;
  static const double _sumColW = 58.0;
  static const double _pctColW = 58.0;
  static const double _initGradeW = 66.0;
  static const double _qgColW = 56.0;
  static const double _remarksW = 76.0;
  static const double _rowH = 44.0;
  static const double _hdrH1 = 26.0;
  static const double _hdrH2 = 36.0;

  @override
  void initState() {
    super.initState();
    _scoreFocus.addListener(() {
      if (!_scoreFocus.hasFocus && _editingKey != null) _commitScore();
    });
    _qgFocus.addListener(() {
      if (!_qgFocus.hasFocus && _editingQgStudentId != null) _commitQg();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _scoreFocus.dispose();
    _qgCtrl.dispose();
    _qgFocus.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    await ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);

    final configState = ref.read(gradingConfigProvider);
    if (!_initialCheckDone && mounted) {
      _initialCheckDone = true;
      if (!configState.isConfigured && !configState.isLoading && configState.error == null) {
        _navigateToSetup();
        return;
      }
    }

    if (configState.isConfigured) {
      _loadItemsAndSummary();
    }
  }

  void _loadItemsAndSummary() {
    print('*** CLASS RECORD PAGE: Loading items and summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    PageLogger.instance.log('Loading items and summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    
    ref.read(gradeItemsProvider.notifier).setQuarter(_selectedQuarter);
    ref.read(gradeItemsProvider.notifier).setComponent(''); // load all components
    
    print('*** CLASS RECORD PAGE: Loading grade items for class: ${widget.classId}');
    PageLogger.instance.log('Loading grade items for class: ${widget.classId}');
    ref.read(gradeItemsProvider.notifier).loadItems(widget.classId).then((_) {
      print('*** CLASS RECORD PAGE: Grade items loaded, starting backfill from activities for quarter: $_selectedQuarter');
      PageLogger.instance.log('Grade items loaded, starting backfill from activities for quarter: $_selectedQuarter');
      ref.read(gradeItemsProvider.notifier).backfillFromActivities(widget.classId, _selectedQuarter).then((_) {
        print('*** CLASS RECORD PAGE: Backfill from activities completed for quarter: $_selectedQuarter');
        PageLogger.instance.log('Backfill from activities completed for quarter: $_selectedQuarter');
      }).catchError((e) {
        print('*** CLASS RECORD PAGE: Error in backfill from activities for quarter: $_selectedQuarter: $e');
        PageLogger.instance.error('Error in backfill from activities for quarter: $_selectedQuarter', e);
      });
    }).catchError((e) {
      print('*** CLASS RECORD PAGE: Error loading grade items for class: ${widget.classId}: $e');
      PageLogger.instance.error('Error loading grade items for class: ${widget.classId}', e);
    });
    
    print('*** CLASS RECORD PAGE: Loading quarterly grades summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    PageLogger.instance.log('Loading quarterly grades summary for class: ${widget.classId}, quarter: $_selectedQuarter');
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedQuarter)
        .catchError((e) {
          print('*** CLASS RECORD PAGE: Error loading quarterly grades summary: $e');
          PageLogger.instance.error('Error loading quarterly grades summary', e);
        });
  }

  void _navigateToSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassGradingSetupPage(classId: widget.classId),
      ),
    );
    if (result == true && mounted) {
      _initialCheckDone = false;
      _loadData();
    }
  }

  void _onQuarterChanged(int quarter) {
    PageLogger.instance.log('Quarter changed from $_selectedQuarter to $quarter');
    setState(() => _selectedQuarter = quarter);
    
    ref.read(gradeItemsProvider.notifier).setQuarter(quarter);
    ref.read(gradeItemsProvider.notifier).setComponent('');
    
    PageLogger.instance.log('Loading grade items for new quarter: $quarter');
    ref.read(gradeItemsProvider.notifier).loadItems(widget.classId).then((_) {
      PageLogger.instance.log('Starting backfill for quarter: $quarter');
      ref.read(gradeItemsProvider.notifier).backfillFromActivities(widget.classId, quarter);
    });
    
    PageLogger.instance.log('Loading quarterly grades summary for new quarter: $quarter');
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, quarter);
  }

  // ── Score inline editing ─────────────────────────────────────────────────

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scoreFocus.requestFocus());
  }

  void _commitScore() {
    final score = double.tryParse(_scoreCtrl.text.trim());
    if (score != null && _editingStudentId != null && _editingItemId != null) {
      final existing = _editingExistingScore;
      if (existing != null && existing.isAutoPopulated) {
        ref.read(gradeScoresProvider.notifier).setOverride(existing.id, score);
      } else {
        ref.read(gradeScoresProvider.notifier).saveScores(_editingItemId!, [
          {'student_id': _editingStudentId!, 'score': score},
        ]);
      }
    }
    if (mounted) {
      setState(() {
        _editingKey = null;
        _editingStudentId = null;
        _editingItemId = null;
        _editingExistingScore = null;
      });
    }
  }

  void _cancelScore() {
    if (!mounted) return;
    setState(() {
      _editingKey = null;
      _editingStudentId = null;
      _editingItemId = null;
      _editingExistingScore = null;
    });
  }

  // ── QG inline editing ────────────────────────────────────────────────────

  void _startQg(String studentId, int? currentQg) {
    if (_editingKey != null) _commitScore();
    if (_editingQgStudentId != null) _commitQg();
    setState(() {
      _editingQgStudentId = studentId;
      _qgCtrl.text = currentQg?.toString() ?? '';
      _qgCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _qgCtrl.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _qgFocus.requestFocus());
  }

  void _commitQg() {
    final grade = int.tryParse(_qgCtrl.text.trim());
    if (grade != null && _editingQgStudentId != null) {
      ref.read(quarterlyGradesProvider.notifier).updatePeriodGrade(
            classId: widget.classId,
            studentId: _editingQgStudentId!,
            quarter: _selectedQuarter,
            transmutedGrade: grade,
          );
    }
    if (mounted) setState(() => _editingQgStudentId = null);
  }

  void _cancelQg() {
    if (mounted) setState(() => _editingQgStudentId = null);
  }

  // ── Add item ─────────────────────────────────────────────────────────────

  void _showAddGradeItemDialog() {
    showAddGradeItemDialog(
      context: context,
      classId: widget.classId,
      selectedQuarter: _selectedQuarter,
      ref: ref,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  GradeConfig? _configForQuarter(List<dynamic> configs) {
    for (final c in configs) {
      if ((c as GradeConfig).gradingPeriodNumber == _selectedQuarter) return c;
    }
    return configs.isNotEmpty ? configs.first as GradeConfig : null;
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final configState = ref.watch(gradingConfigProvider);
    final itemsState = ref.watch(gradeItemsProvider);
    final scoresState = ref.watch(gradeScoresProvider);
    final gradesState = ref.watch(quarterlyGradesProvider);

    final students = classState.currentClassDetail?.students ?? [];
    final config = _configForQuarter(configState.configs);

    ref.listen<GradeItemsState>(gradeItemsProvider, (prev, next) {
      print('*** CLASS RECORD PAGE: Grade items state changed - loading: ${next.isLoading}, items count: ${next.items.length}');
      PageLogger.instance.log('Grade items state changed - loading: ${next.isLoading}, items count: ${next.items.length}');
      
      if (prev?.isLoading == true && !next.isLoading) {
        print('*** CLASS RECORD PAGE: Grade items loaded - total items: ${next.items.length}');
        PageLogger.instance.log('Grade items loaded - total items: ${next.items.length}');
        
        for (final item in next.items) {
          print('*** CLASS RECORD PAGE: Grade item: ${item.title} (${item.component}) - source: ${item.sourceType}, sourceId: ${item.sourceId}');
          PageLogger.instance.log('Grade item: ${item.title} (${item.component}) - source: ${item.sourceType}, sourceId: ${item.sourceId}');
        }
        
        if (next.items.isNotEmpty) {
          final ids = next.items.map((i) => i.id).toList();
          print('*** CLASS RECORD PAGE: Loading scores for ${ids.length} grade items');
          PageLogger.instance.log('Loading scores for ${ids.length} grade items');
          ref.read(gradeScoresProvider.notifier).loadScoresForItems(ids);
          
          // Generate scores for grade items that don't have scores yet
          print('*** CLASS RECORD PAGE: Generating scores for grade items');
          PageLogger.instance.log('Generating scores for grade items');
          ref.read(gradeItemsProvider.notifier).generateScoresForItems(widget.classId);
        } else {
          print('*** CLASS RECORD PAGE: No grade items found for class: ${widget.classId}, quarter: $_selectedQuarter');
          PageLogger.instance.warn('No grade items found for class: ${widget.classId}, quarter: $_selectedQuarter');
        }
      }
    });

    final wwItems = itemsState.items
        .where((i) => i.component == 'ww')
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final ptItems = itemsState.items
        .where((i) => i.component == 'pt')
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final qaItems = itemsState.items
        .where((i) => i.component == 'qa')
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Score lookup: studentId → {itemId → GradeScore}
    final Map<String, Map<String, GradeScore>> scoreLookup = {};
    for (final entry in scoresState.scoresByItem.entries) {
      for (final score in entry.value) {
        scoreLookup
            .putIfAbsent(score.studentId, () => {})[score.gradeItemId] = score;
      }
    }

    // QG lookup: studentId → quarterly_grade (int?)
    final Map<String, int?> qgLookup = {};
    for (final row in (gradesState.summary ?? [])) {
      final sid = row['student_id'] as String?;
      final qg = row['quarterly_grade'];
      if (sid != null) {
        qgLookup[sid] = qg == null
            ? null
            : (qg is double
                ? qg.round()
                : (qg is int ? qg : int.tryParse(qg.toString())));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
                title: 'Class Record', showBackButton: true),

            // Quarter chips + actions
            QuarterSelector(
              selectedQuarter: _selectedQuarter,
              onQuarterChanged: _onQuarterChanged,
              onComputeGrades: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(quarterlyGradesProvider.notifier)
                    .computeGrades(widget.classId, _selectedQuarter);
                if (!mounted) return;
                ref
                    .read(quarterlyGradesProvider.notifier)
                    .loadSummary(widget.classId, _selectedQuarter);
                messenger.showSnackBar(
                    const SnackBar(content: Text('Grades computed')));
              },
              onFinalGrades: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeSummaryPage(
                    classId: widget.classId,
                    initialQuarter: _selectedQuarter,
                  ),
                ),
              ),
              onGradingSettings: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassGradingSetupPage(
                    classId: widget.classId,
                  ),
                ),
              ),
            ),

            // Content
            if (configState.isLoading ||
                (configState.isConfigured &&
                    itemsState.isLoading &&
                    itemsState.items.isEmpty))
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF2B2B2B), strokeWidth: 2.5),
                ),
              )
            else if (!configState.isConfigured)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune_outlined,
                          size: 64, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 16),
                      Text('Grading not configured',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF999999))),
                      SizedBox(height: 8),
                      Text('Set up grading weights to get started',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFFCCCCCC))),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _buildSheet(
                  students: students,
                  wwItems: wwItems,
                  ptItems: ptItems,
                  qaItems: qaItems,
                  config: config,
                  scoreLookup: scoreLookup,
                  qgLookup: qgLookup,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: configState.isConfigured
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2B2B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: _showAddGradeItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ── DepEd single-sheet layout ─────────────────────────────────────────────

  double _secW(int n) => n * _scoreColW + _sumColW * 2 + _pctColW * 2;

  Widget _buildSheet({
    required List<Participant> students,
    required List<GradeItem> wwItems,
    required List<GradeItem> ptItems,
    required List<GradeItem> qaItems,
    required GradeConfig? config,
    required Map<String, Map<String, GradeScore>> scoreLookup,
    required Map<String, int?> qgLookup,
  }) {
    final wwW = config?.wwWeight ?? 40.0;
    final ptW = config?.ptWeight ?? 40.0;
    final qaW = config?.qaWeight ?? 20.0;

    final wwSecW = _secW(wwItems.length);
    final ptSecW = _secW(ptItems.length);
    final qaSecW = _secW(qaItems.length);
    const summaryW = _initGradeW + _qgColW + _remarksW;
    final scrollW = wwSecW + ptSecW + qaSecW + summaryW;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Frozen name column ───────────────────────────────────────────
          SizedBox(
            width: _nameColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: group label (blank)
                Container(
                  height: _hdrH1,
                  color: const Color(0xFFF0F4F8),
                ),
                // Row 2: column label
                _hdrCell("Learner's Name", _nameColW, _hdrH2,
                    align: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10)),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                // Student rows
                for (int i = 0; i < students.length; i++) ...[
                  Container(
                    height: _rowH,
                    width: _nameColW,
                    color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${i + 1}. ${students[i].student.fullName}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B2B2B)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (i < students.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ],
              ],
            ),
          ),

          // Vertical separator
          Container(width: 1, color: const Color(0xFFCCCCCC)),

          // ── Scrollable data columns ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: section group headers
                    SizedBox(
                      height: _hdrH1,
                      child: Row(
                        children: [
                          _grpCell('WRITTEN WORKS (${wwW.toStringAsFixed(0)}%)',
                              wwSecW, const Color(0xFFDEEBFF)),
                          _grpCell(
                              'PERFORMANCE TASKS (${ptW.toStringAsFixed(0)}%)',
                              ptSecW,
                              const Color(0xFFDCF5E4)),
                          _grpCell(
                              'QUARTERLY ASSESSMENT (${qaW.toStringAsFixed(0)}%)',
                              qaSecW,
                              const Color(0xFFFFF2D6)),
                          _grpCell('SUMMARY', summaryW,
                              const Color(0xFFF0E6FF)),
                        ],
                      ),
                    ),
                    // Row 2: column sub-headers
                    SizedBox(
                      height: _hdrH2,
                      child: Row(
                        children: [
                          ..._sectionHdrs(wwItems, 'WW'),
                          ..._sectionHdrs(ptItems, 'PT'),
                          ..._sectionHdrs(qaItems, 'QA'),
                          _hdrCell('Initial', _initGradeW, _hdrH2),
                          _hdrCell('QG', _qgColW, _hdrH2),
                          _hdrCell('Remarks', _remarksW, _hdrH2),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFDDDDDD)),

                    // Data rows
                    for (int i = 0; i < students.length; i++) ...[
                      _buildDataRow(
                        index: i,
                        participant: students[i],
                        wwItems: wwItems,
                        ptItems: ptItems,
                        qaItems: qaItems,
                        config: config,
                        scoreLookup: scoreLookup,
                        qgLookup: qgLookup,
                        wwW: wwW,
                        ptW: ptW,
                        qaW: qaW,
                      ),
                      if (i < students.length - 1)
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
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

  List<Widget> _sectionHdrs(List<GradeItem> items, String prefix) => [
        for (int i = 0; i < items.length; i++)
          _hdrCell('$prefix${i + 1}', _scoreColW, _hdrH2),
        _hdrCell('Total', _sumColW, _hdrH2),
        _hdrCell('HS', _sumColW, _hdrH2),
        _hdrCell('%', _pctColW, _hdrH2),
        _hdrCell('WS', _pctColW, _hdrH2),
      ];

  Widget _buildDataRow({
    required int index,
    required Participant participant,
    required List<GradeItem> wwItems,
    required List<GradeItem> ptItems,
    required List<GradeItem> qaItems,
    required GradeConfig? config,
    required Map<String, Map<String, GradeScore>> scoreLookup,
    required Map<String, int?> qgLookup,
    required double wwW,
    required double ptW,
    required double qaW,
  }) {
    final sid = participant.student.id;
    final bgColor = index.isEven ? Colors.white : const Color(0xFFFAFAFA);

    final wwStats = _computeStats(sid, wwItems, scoreLookup, wwW);
    final ptStats = _computeStats(sid, ptItems, scoreLookup, ptW);
    final qaStats = _computeStats(sid, qaItems, scoreLookup, qaW);

    double? initialGrade;
    final parts = [wwStats.ws, ptStats.ws, qaStats.ws];
    final available = parts.whereType<double>().toList();
    if (available.isNotEmpty) {
      initialGrade = available.fold<double>(0.0, (sum, v) => sum + v);
    }

    final storedQg = qgLookup[sid];
    final computedQg = initialGrade != null
        ? TransmutationUtil.transmute(initialGrade).round()
        : null;
    final displayQg = storedQg ?? computedQg;
    final remarks =
        displayQg != null ? (displayQg >= 75 ? 'Passed' : 'Failed') : null;
    final isEditingQg = _editingQgStudentId == sid;

    return SizedBox(
      height: _rowH,
      child: Row(
        children: [
          ..._sectionScoreCells(participant, wwItems, scoreLookup, wwStats, bgColor),
          ..._sectionScoreCells(participant, ptItems, scoreLookup, ptStats, bgColor),
          ..._sectionScoreCells(participant, qaItems, scoreLookup, qaStats, bgColor),
          // Initial grade
          _computedCell(
              initialGrade != null ? _fmt(initialGrade) : '--',
              _initGradeW,
              bgColor,
              bold: true),
          // QG (editable)
          if (isEditingQg)
            _inlineCell(_qgCtrl, _qgFocus, _commitQg, _cancelQg, _qgColW, bgColor)
          else
            GestureDetector(
              onTap: () => _startQg(sid, displayQg),
              child: _computedCell(
                displayQg?.toString() ?? '--',
                _qgColW,
                bgColor,
                bold: true,
                color: storedQg != null
                    ? const Color(0xFF1565C0)
                    : (displayQg != null
                        ? const Color(0xFF2B2B2B)
                        : null),
              ),
            ),
          // Remarks
          _remarksCell(remarks, bgColor),
        ],
      ),
    );
  }

  List<Widget> _sectionScoreCells(
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
            return _inlineCell(
                _scoreCtrl, _scoreFocus, _commitScore, _cancelScore,
                _scoreColW, bgColor);
          }
          return GestureDetector(
            onTap: () => _startScore(sid, item.id, gs),
            child: _scoreCell(
              displayScore != null ? _fmt(displayScore) : '--',
              _scoreColW,
              bgColor,
              isOverride: isOverride,
              empty: displayScore == null,
            ),
          );
        }(),
      ],
      _computedCell(
          stats.total != null ? _fmt(stats.total!) : '--', _sumColW, bgColor),
      _computedCell(
          items.isNotEmpty ? _fmt(stats.hs) : '--', _sumColW, bgColor),
      _computedCell(
          stats.pct != null ? '${stats.pct!.toStringAsFixed(1)}%' : '--',
          _pctColW,
          bgColor),
      _computedCell(
          stats.ws != null ? _fmt(stats.ws!) : '--', _pctColW, bgColor,
          bold: true),
    ];
  }

  // ── Cell widget builders ──────────────────────────────────────────────────

  Widget _grpCell(String label, double width, Color color) {
    return Container(
      width: width,
      height: _hdrH1,
      color: color,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
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
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 4),
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6F8),
        border: Border(
          right: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
          bottom: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      alignment: align,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
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
      height: _rowH,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
            right: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isOverride ? FontWeight.w700 : FontWeight.w400,
          color: isOverride
              ? const Color(0xFF1565C0)
              : (empty ? const Color(0xFFCCCCCC) : const Color(0xFF2B2B2B)),
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
      height: _rowH,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
            right: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color ??
              (text == '--' ? const Color(0xFFCCCCCC) : const Color(0xFF555555)),
        ),
      ),
    );
  }

  Widget _remarksCell(String? remarks, Color bgColor) {
    if (remarks == null) {
      return _computedCell('--', _remarksW, bgColor);
    }
    final passed = remarks == 'Passed';
    return Container(
      width: _remarksW,
      height: _rowH,
      color: const Color(0xFFF8F9FA),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: passed
              ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
              : const Color(0xFFE57373).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          remarks,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color:
                passed ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
      height: _rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
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
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => onCommit(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
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
