import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_stats_footer.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_table_cells.dart';
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
      backgroundColor: AppColors.backgroundSecondary,
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
                      selectedColor: AppColors.accentCharcoal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedQuarter == q
                            ? Colors.white
                            : AppColors.foregroundSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedQuarter == q
                              ? AppColors.accentCharcoal
                              : AppColors.borderLight,
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
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.accentCharcoal,
                unselectedLabelColor: AppColors.foregroundTertiary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                indicator: BoxDecoration(
                  color: AppColors.backgroundTertiary,
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
          color: AppColors.accentCharcoal,
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
            style: const TextStyle(fontSize: 14, color: AppColors.semanticError),
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
            Icon(Icons.assessment_outlined, size: 48, color: AppColors.foregroundLight),
            SizedBox(height: 12),
            Text(
              'No grade summary available',
              style: TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
            ),
            SizedBox(height: 4),
            Text(
              'Compute grades from the Class Record first',
              style: TextStyle(fontSize: 12, color: AppColors.foregroundLight),
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
        GradeStatsFooter(summary: summary),
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
                    GradeTableCells.headerCell('Student', nameWidth, align: Alignment.centerLeft),
                    ...columns.map((col) => GradeTableCells.headerCell(
                          col,
                          col == 'Descriptor' ? 130.0 : cellWidth,
                        )),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

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
                        _fmtScore(wwScore),
                        cellWidth,
                        cellHeight,
                      ),
                      GradeTableCells.dataCell(
                        _fmtScore(ptScore),
                        cellWidth,
                        cellHeight,
                      ),
                      GradeTableCells.dataCell(
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
                                      color: AppColors.accentCharcoal,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppColors.accentCharcoal,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppColors.accentCharcoal,
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
                                    color: AppColors.foregroundLight,
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
  // Final Grades Tab
  // ---------------------------------------------------------------------------

  Widget _buildFinalGradesTab() {
    if (_finalGradesLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentCharcoal,
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
                style: const TextStyle(fontSize: 14, color: AppColors.semanticError),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadFinalGrades,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.foregroundPrimary),
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
            Icon(Icons.grade_outlined, size: 48, color: AppColors.foregroundLight),
            SizedBox(height: 12),
            Text(
              'No final grades available',
              style: TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
            ),
            SizedBox(height: 4),
            Text(
              'Compute quarterly grades first',
              style: TextStyle(fontSize: 12, color: AppColors.foregroundLight),
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
                    GradeTableCells.headerCell('Student', nameWidth, align: Alignment.centerLeft),
                    GradeTableCells.headerCell('Q1', cellWidth),
                    GradeTableCells.headerCell('Q2', cellWidth),
                    GradeTableCells.headerCell('Q3', cellWidth),
                    GradeTableCells.headerCell('Q4', cellWidth),
                    GradeTableCells.headerCell('Final', fgWidth),
                    GradeTableCells.headerCell('GA', gaWidth),
                    GradeTableCells.headerCell('Descriptor', descriptorWidth),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

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
                      GradeTableCells.dataCell(q1?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(q2?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(q3?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(q4?.toString() ?? '--', cellWidth, cellHeight),
                      GradeTableCells.dataCell(
                        finalGrade?.toString() ?? '--',
                        fgWidth,
                        cellHeight,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: finalGrade != null
                              ? AppColors.foregroundPrimary
                              : AppColors.foregroundLight,
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
                        return GradeTableCells.dataCell(
                          ga?.toString() ?? '--',
                          gaWidth,
                          cellHeight,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ga != null
                                ? AppColors.foregroundPrimary
                                : AppColors.foregroundLight,
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
                                    color: AppColors.foregroundLight,
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
