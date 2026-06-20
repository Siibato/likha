import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/desktop_final_grade_table.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/desktop_grade_term_chips.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/desktop_term_grade_table.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTermData());
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

  void _loadTermData() {
    ref.read(termGradesProvider.notifier).loadSummary(widget.classId, _selectedTerm);
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
    final termState = ref.watch(termGradesProvider);

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
            DesktopGradeTermChips(
              selectedTerm: _selectedTerm,
              onTermChanged: (q) {
                setState(() => _selectedTerm = q);
                _loadTermData();
              },
            ),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermTab(termState),
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
        tabs: const [Tab(text: 'Term'), Tab(text: 'Final Grades')],
      ),
    );
  }

  Widget _buildTermTab(dynamic termState) {
    if (termState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (termState.error != null) {
      return Center(
        child: Text(termState.error!, style: const TextStyle(color: AppColors.semanticError)),
      );
    }
    final summary = (termState.summary as List?)?.cast<Map<String, dynamic>>() ?? [];
    return DesktopTermGradeTable(
      summary: summary,
      onQgChanged: (studentId, grade) {
        ref.read(termGradesProvider.notifier).updateTermGrade(
          classId: widget.classId,
          studentId: studentId,
          term: _selectedTerm,
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
