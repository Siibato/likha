import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/desktop_final_grade_table.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/desktop_grade_quarter_chips.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/desktop_quarterly_grade_table.dart';

class GradeSummaryDesktop extends ConsumerStatefulWidget {
  final String classId;
  final int initialQuarter;

  const GradeSummaryDesktop({
    super.key,
    required this.classId,
    this.initialQuarter = 1,
  });

  @override
  ConsumerState<GradeSummaryDesktop> createState() => _GradeSummaryDesktopState();
}

class _GradeSummaryDesktopState extends ConsumerState<GradeSummaryDesktop>
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuarterlyData());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      _loadFinalGradesIfNeeded();
    }
  }

  void _loadQuarterlyData() {
    ref.read(quarterlyGradesProvider.notifier).loadSummary(widget.classId, _selectedQuarter);
  }

  Future<void> _loadFinalGradesIfNeeded() async {
    if (_finalGrades != null) return;

    setState(() {
      _finalGradesLoading = true;
      _finalGradesError = null;
    });

    try {
      final result = await sl<GetFinalGrades>().call(widget.classId);
      result.fold(
        (failure) {
          if (mounted) setState(() { _finalGradesLoading = false; _finalGradesError = failure.message; });
        },
        (grades) {
          if (mounted) setState(() { _finalGrades = grades; _finalGradesLoading = false; });
        },
      );
      ref.read(generalAverageProvider.notifier).loadGeneralAverages(widget.classId);
    } catch (e) {
      if (mounted) setState(() { _finalGradesLoading = false; _finalGradesError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quarterlyState = ref.watch(quarterlyGradesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Grade Summary',
        scrollable: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foregroundDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesktopGradeQuarterChips(
              selectedQuarter: _selectedQuarter,
              onQuarterChanged: (q) {
                setState(() => _selectedQuarter = q);
                _loadQuarterlyData();
              },
            ),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuarterlyTab(quarterlyState),
                  _buildFinalGradesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.foregroundDark,
        unselectedLabelColor: AppColors.foregroundSecondary,
        indicatorColor: AppColors.foregroundDark,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: const [Tab(text: 'Quarterly'), Tab(text: 'Final Grades')],
      ),
    );
  }

  Widget _buildQuarterlyTab(dynamic quarterlyState) {
    if (quarterlyState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (quarterlyState.error != null) {
      return Center(
        child: Text(quarterlyState.error!, style: const TextStyle(color: AppColors.semanticError)),
      );
    }
    final summary = (quarterlyState.summary as List?)?.cast<Map<String, dynamic>>() ?? [];
    return DesktopQuarterlyGradeTable(
      summary: summary,
      onQgChanged: (studentId, grade) {
        ref.read(quarterlyGradesProvider.notifier).updatePeriodGrade(
          classId: widget.classId,
          studentId: studentId,
          quarter: _selectedQuarter,
          transmutedGrade: grade,
        );
      },
    );
  }

  Widget _buildFinalGradesTab() {
    if (_finalGradesLoading) return const Center(child: CircularProgressIndicator());
    if (_finalGradesError != null) {
      return Center(
        child: Text(_finalGradesError!, style: const TextStyle(color: AppColors.semanticError)),
      );
    }
    return DesktopFinalGradeTable(finalGrades: _finalGrades ?? []);
  }
}
