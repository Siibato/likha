import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/final_grade_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_stats_footer.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/quarterly_grade_table.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedQuarter = widget.initialQuarter;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
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

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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
          child: QuarterlyGradeTable(
            summary: summary,
            wwWeight: wwWeight,
            ptWeight: ptWeight,
            qaWeight: qaWeight,
            onQgChanged: (studentId, grade) {
              ref.read(quarterlyGradesProvider.notifier).updatePeriodGrade(
                    classId: widget.classId,
                    studentId: studentId,
                    quarter: _selectedQuarter,
                    transmutedGrade: grade,
                  );
            },
          ),
        ),
        GradeStatsFooter(summary: summary),
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

    return FinalGradeTable(data: _finalGrades!);
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

}
