import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class GradeSummaryPage extends ConsumerStatefulWidget {
  final String classId;
  final int initialQuarter;

  const GradeSummaryPage({
    super.key,
    required this.classId,
    this.initialQuarter = 1,
  });

  @override
  ConsumerState<GradeSummaryPage> createState() => _GradeSummaryPageState();
}

class _GradeSummaryPageState extends ConsumerState<GradeSummaryPage>
    with SingleTickerProviderStateMixin {
  late int _selectedQuarter;
  late TabController _tabController;

  List<Map<String, dynamic>>? _finalGrades;
  bool _finalGradesLoading = false;
  String? _finalGradesError;

  // QG inline editing
  String? _editingStudentId;
  final _qgEditController = TextEditingController();
  final _qgFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedQuarter = widget.initialQuarter;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _qgFocusNode.addListener(() {
      if (!_qgFocusNode.hasFocus && _editingStudentId != null) {
        _commitQgEdit();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuarterlySummary();
      ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      if (_finalGrades == null) _loadFinalGrades();
      ref.read(generalAverageProvider.notifier).loadGeneralAverages(widget.classId);
    }
  }

  void _loadQuarterlySummary() {
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedQuarter);
  }

  Future<void> _loadFinalGrades() async {
    setState(() {
      _finalGradesLoading = true;
      _finalGradesError = null;
    });

    final result = await sl<GetFinalGrades>().call(widget.classId);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _finalGradesLoading = false;
        _finalGradesError = failure.toString();
      }),
      (grades) => setState(() {
        _finalGradesLoading = false;
        _finalGrades = grades;
      }),
    );
  }

  void _onQuarterChanged(int quarter) {
    setState(() => _selectedQuarter = quarter);
    _loadQuarterlySummary();
  }

  void _startQgEdit(String studentId, int? currentGrade) {
    if (_editingStudentId != null) _commitQgEdit();
    setState(() {
      _editingStudentId = studentId;
      _qgEditController.text =
          currentGrade != null ? currentGrade.toString() : '';
      _qgEditController.selection = TextSelection.fromPosition(
        TextPosition(offset: _qgEditController.text.length),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qgFocusNode.requestFocus();
    });
  }

  void _commitQgEdit() {
    final raw = _qgEditController.text.trim();
    final grade = int.tryParse(raw);
    if (grade != null && _editingStudentId != null) {
      ref.read(quarterlyGradesProvider.notifier).updatePeriodGrade(
        classId: widget.classId,
        studentId: _editingStudentId!,
        quarter: _selectedQuarter,
        transmutedGrade: grade,
      );
    }
    if (mounted) setState(() => _editingStudentId = null);
  }

  void _cancelQgEdit() {
    if (mounted) setState(() => _editingStudentId = null);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _qgEditController.dispose();
    _qgFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradesState = ref.watch(quarterlyGradesProvider);
    final configState = ref.watch(gradingConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Grade Summary',
              showBackButton: true,
            ),

            // Quarter selector
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: List.generate(4, (i) {
                  final q = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Q$q'),
                      selected: _selectedQuarter == q,
                      selectedColor: const Color(0xFF2B2B2B),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedQuarter == q
                            ? Colors.white
                            : const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedQuarter == q
                              ? const Color(0xFF2B2B2B)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      onSelected: (_) => _onQuarterChanged(q),
                    ),
                  );
                }),
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2B2B2B),
                unselectedLabelColor: const Color(0xFF999999),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicator: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Quarterly'),
                  Tab(text: 'Final Grades'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuarterlyTab(gradesState, configState),
                  _buildFinalGradesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quarterly Tab
  // ---------------------------------------------------------------------------

  Widget _buildQuarterlyTab(
    PeriodGradesState gradesState,
    GradingConfigState configState,
  ) {
    if (gradesState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2B2B2B),
          strokeWidth: 2.5,
        ),
      );
    }

    if (gradesState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            gradesState.error!,
            style: const TextStyle(fontSize: 14, color: Color(0xFFE57373)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final summary = gradesState.summary;
    if (summary == null || summary.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'No grade summary available',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            SizedBox(height: 4),
            Text(
              'Compute grades from the Class Record first',
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
            ),
          ],
        ),
      );
    }

    // Resolve component weights for the selected quarter
    final wwWeight = _getWeight(configState.configs, 'ww');
    final ptWeight = _getWeight(configState.configs, 'pt');
    final qaWeight = _getWeight(configState.configs, 'qa');

    return Column(
      children: [
        Expanded(
          child: _buildQuarterlyTable(summary, wwWeight, ptWeight, qaWeight),
        ),
        _buildStatsFooter(summary),
      ],
    );
  }

  Widget _buildQuarterlyTable(
    List<Map<String, dynamic>> summary,
    double wwWeight,
    double ptWeight,
    double qaWeight,
  ) {
    const nameWidth = 130.0;
    const cellWidth = 80.0;
    const cellHeight = 44.0;

    final columns = [
      'WW (${wwWeight.toStringAsFixed(0)}%)',
      'PT (${ptWeight.toStringAsFixed(0)}%)',
      'QA (${qaWeight.toStringAsFixed(0)}%)',
      'QG',
      'Descriptor',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    _headerCell('Student', nameWidth, align: Alignment.centerLeft),
                    ...columns.map((col) => _headerCell(
                          col,
                          col == 'Descriptor' ? 130.0 : cellWidth,
                        )),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),

              // Rows
              ...summary.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final studentId = row['student_id'] as String? ?? '';
                final studentName =
                    row['student_name'] as String? ?? 'Unknown';
                final wwScore = _numOrNull(row['ww_weighted_score']);
                final ptScore = _numOrNull(row['pt_weighted_score']);
                final qaScore = _numOrNull(row['qa_weighted_score']);
                final qg = _numOrNull(row['quarterly_grade'])?.round();
                final descriptor =
                    qg != null ? TransmutationUtil.getDescriptor(qg) : null;
                final descriptorColor =
                    qg != null ? TransmutationUtil.getDescriptorColor(qg) : null;
                final isEditingQg = _editingStudentId == studentId;

                return Container(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white
                        : const Color(0xFFFAFAFA),
                  ),
                  child: Row(
                    children: [
                      _dataCell(
                        studentName,
                        nameWidth,
                        cellHeight,
                        align: Alignment.centerLeft,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      _dataCell(
                        _fmtScore(wwScore),
                        cellWidth,
                        cellHeight,
                      ),
                      _dataCell(
                        _fmtScore(ptScore),
                        cellWidth,
                        cellHeight,
                      ),
                      _dataCell(
                        _fmtScore(qaScore),
                        cellWidth,
                        cellHeight,
                      ),
                      // QG — inline-editable
                      if (isEditingQg)
                        SizedBox(
                          width: cellWidth,
                          height: cellHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: CallbackShortcuts(
                              bindings: {
                                const SingleActivator(
                                        LogicalKeyboardKey.escape):
                                    _cancelQgEdit,
                              },
                              child: TextField(
                                controller: _qgEditController,
                                focusNode: _qgFocusNode,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(fontSize: 13),
                                onSubmitted: (_) => _commitQgEdit(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
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
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _startQgEdit(studentId, qg),
                          child: _dataCell(
                            qg?.toString() ?? '--',
                            cellWidth,
                            cellHeight,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: qg != null
                                  ? const Color(0xFF2B2B2B)
                                  : const Color(0xFFCCCCCC),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: 130,
                        height: cellHeight,
                        child: Center(
                          child: descriptor != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(descriptorColor!)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    descriptor,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(descriptorColor),
                                    ),
                                  ),
                                )
                              : const Text(
                                  '--',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                        ),
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

  Widget _buildStatsFooter(List<Map<String, dynamic>> summary) {
    final grades = summary
        .map((r) => _numOrNull(r['quarterly_grade']))
        .whereType<double>()
        .toList();

    if (grades.isEmpty) {
      return const SizedBox.shrink();
    }

    final transmuted = grades.map((g) => g.round()).toList();
    final avg = transmuted.reduce((a, b) => a + b) / transmuted.length;
    final highest = transmuted.reduce((a, b) => a > b ? a : b);
    final lowest = transmuted.reduce((a, b) => a < b ? a : b);
    final passing = transmuted.where((g) => g >= 75).length;
    final passRate =
        ((passing / transmuted.length) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Average', avg.toStringAsFixed(1)),
          _statItem('Highest', highest.toString()),
          _statItem('Lowest', lowest.toString()),
          _statItem('Pass Rate', '$passRate%'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Final Grades Tab
  // ---------------------------------------------------------------------------

  Widget _buildFinalGradesTab() {
    if (_finalGradesLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2B2B2B),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_finalGradesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _finalGradesError!,
                style: const TextStyle(fontSize: 14, color: Color(0xFFE57373)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadFinalGrades,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFF2B2B2B)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_finalGrades == null || _finalGrades!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'No final grades available',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            SizedBox(height: 4),
            Text(
              'Compute quarterly grades first',
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
            ),
          ],
        ),
      );
    }

    return _buildFinalGradesTable(_finalGrades!);
  }

  Widget _buildFinalGradesTable(List<Map<String, dynamic>> data) {
    const nameWidth = 130.0;
    const cellWidth = 64.0;
    const fgWidth = 80.0;
    const gaWidth = 64.0;
    const descriptorWidth = 130.0;
    const cellHeight = 44.0;

    final gaState = ref.watch(generalAverageProvider);
    final gaStudents = gaState.response?.students ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    _headerCell('Student', nameWidth, align: Alignment.centerLeft),
                    _headerCell('Q1', cellWidth),
                    _headerCell('Q2', cellWidth),
                    _headerCell('Q3', cellWidth),
                    _headerCell('Q4', cellWidth),
                    _headerCell('Final', fgWidth),
                    _headerCell('GA', gaWidth),
                    _headerCell('Descriptor', descriptorWidth),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),

              // Rows
              ...data.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final studentName =
                    row['student_name'] as String? ?? 'Unknown';
                final q1 = _intOrNull(row['q1']);
                final q2 = _intOrNull(row['q2']);
                final q3 = _intOrNull(row['q3']);
                final q4 = _intOrNull(row['q4']);

                // Compute final grade as average of non-null quarters
                final quarterGrades = [q1, q2, q3, q4].whereType<int>().toList();
                final finalGrade = quarterGrades.isNotEmpty
                    ? (quarterGrades.reduce((a, b) => a + b) /
                            quarterGrades.length)
                        .round()
                    : null;
                final descriptor = finalGrade != null
                    ? TransmutationUtil.getDescriptor(finalGrade)
                    : null;
                final descriptorColor = finalGrade != null
                    ? TransmutationUtil.getDescriptorColor(finalGrade)
                    : null;

                return Container(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white
                        : const Color(0xFFFAFAFA),
                  ),
                  child: Row(
                    children: [
                      _dataCell(
                        studentName,
                        nameWidth,
                        cellHeight,
                        align: Alignment.centerLeft,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      _dataCell(q1?.toString() ?? '--', cellWidth, cellHeight),
                      _dataCell(q2?.toString() ?? '--', cellWidth, cellHeight),
                      _dataCell(q3?.toString() ?? '--', cellWidth, cellHeight),
                      _dataCell(q4?.toString() ?? '--', cellWidth, cellHeight),
                      _dataCell(
                        finalGrade?.toString() ?? '--',
                        fgWidth,
                        cellHeight,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: finalGrade != null
                              ? const Color(0xFF2B2B2B)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                      // GA column
                      () {
                        final studentId = row['student_id'] as String?;
                        final gaMatch = gaStudents.cast<dynamic>().firstWhere(
                          (s) => s.studentId == studentId ||
                              s.studentName == studentName,
                          orElse: () => null,
                        );
                        final ga = gaMatch?.generalAverage;
                        return _dataCell(
                          ga?.toString() ?? '--',
                          gaWidth,
                          cellHeight,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ga != null
                                ? const Color(0xFF2B2B2B)
                                : const Color(0xFFCCCCCC),
                          ),
                        );
                      }(),
                      SizedBox(
                        width: descriptorWidth,
                        height: cellHeight,
                        child: Center(
                          child: descriptor != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(descriptorColor!)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    descriptor,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(descriptorColor),
                                    ),
                                  ),
                                )
                              : const Text(
                                  '--',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                        ),
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

  // ---------------------------------------------------------------------------
  // Shared table helpers
  // ---------------------------------------------------------------------------

  Widget _headerCell(
    String text,
    double width, {
    Alignment align = Alignment.center,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF999999),
          letterSpacing: 0.3,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width,
    double height, {
    Alignment align = Alignment.center,
    TextStyle? style,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: align,
      child: Text(
        text,
        style: style ??
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: text == '--'
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF2B2B2B),
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  double _getWeight(List<dynamic> configs, String component) {
    for (final config in configs) {
      if (config.quarter == _selectedQuarter) {
        return switch (component) {
          'ww' => config.wwWeight as double,
          'pt' => config.ptWeight as double,
          'qa' => config.qaWeight as double,
          _ => 0.0,
        };
      }
    }
    if (configs.isNotEmpty) {
      final config = configs.first;
      return switch (component) {
        'ww' => config.wwWeight as double,
        'pt' => config.ptWeight as double,
        'qa' => config.qaWeight as double,
        _ => 0.0,
      };
    }
    return 0.0;
  }

  double? _numOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  String _fmtScore(double? score) {
    if (score == null) return '--';
    if (score == score.roundToDouble()) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }
}
