import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/term_utils.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/final_grade_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/grade_stats_footer.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/term_grade_table.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class GradeSummaryPage extends ConsumerStatefulWidget {
  final String classId;
  final int initialTerm;

  const GradeSummaryPage({
    super.key,
    required this.classId,
    this.initialTerm = 1,
  });

  @override
  ConsumerState<GradeSummaryPage> createState() => _GradeSummaryPageState();
}

class _GradeSummaryPageState extends ConsumerState<GradeSummaryPage>
    with SingleTickerProviderStateMixin {
  late int _selectedTerm;
  late TabController _tabController;

  List<Map<String, dynamic>>? _finalGrades;
  bool _finalGradesLoading = false;
  String? _finalGradesError;

  @override
  void initState() {
    super.initState();
    _selectedTerm = widget.initialTerm;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTermSummary();
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

  void _loadTermSummary() {
    ref
        .read(termGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedTerm);
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

  void _onTermChanged(int term) {
    setState(() => _selectedTerm = term);
    _loadTermSummary();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradesState = ref.watch(termGradesProvider);
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

            // Term selector
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: List.generate(termCountFromType(null), (i) {
                  final q = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('T$q'),
                      selected: _selectedTerm == q,
                      selectedColor: AppColors.accentCharcoal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedTerm == q
                            ? Colors.white
                            : AppColors.foregroundSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedTerm == q
                              ? AppColors.accentCharcoal
                              : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (_) => _onTermChanged(q),
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
                  Tab(text: 'Term'),
                  Tab(text: 'Final Grades'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermTab(gradesState, configState),
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
  // Term Tab
  // ---------------------------------------------------------------------------

  Widget _buildTermTab(
    TermGradesState gradesState,
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

    // Resolve component weights for the selected term
    final wwWeight = _getWeight(configState.configs, 'ww');
    final ptWeight = _getWeight(configState.configs, 'pt');
    final qaWeight = _getWeight(configState.configs, 'qa');

    return Column(
      children: [
        Expanded(
          child: TermGradeTable(
            summary: summary,
            wwWeight: wwWeight,
            ptWeight: ptWeight,
            qaWeight: qaWeight,
            onQgChanged: (studentId, grade) {
              ref.read(termGradesProvider.notifier).updateTermGrade(
                    classId: widget.classId,
                    studentId: studentId,
                    term: _selectedTerm,
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
              'Compute term grades first',
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
      if (config.termNumber == _selectedTerm) {
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
