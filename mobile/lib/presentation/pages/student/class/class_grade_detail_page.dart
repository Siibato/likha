import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/usecases/get_my_grade_detail.dart';
import 'package:likha/domain/grading/usecases/get_my_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/final_grade_section.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/grade_component_section.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/grade_item_models.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/grade_summary_section.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/overall_grade_banner.dart';
import 'package:likha/presentation/widgets/mobile/student/grade/quarter_selector.dart';

class StudentClassGradeDetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String className;

  const StudentClassGradeDetailPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<StudentClassGradeDetailPage> createState() =>
      _StudentClassGradeDetailPageState();
}

class _StudentClassGradeDetailPageState
    extends ConsumerState<StudentClassGradeDetailPage> {
  int _selectedQuarter = 1;
  bool _isLoading = false;
  String? _error;

  List<PeriodGrade> _quarterlyGrades = [];
  PeriodGrade? _currentQuarterGrade;
  List<GradeItemDetail> _items = [];
  GradingConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPeriodGrades());
  }

  Future<void> _loadPeriodGrades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<GetMyGrades>()(widget.classId);
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = AppErrorMapper.fromFailure(failure);
          });
        }
      },
      (grades) {
        if (mounted) {
          _quarterlyGrades = grades;
          if (grades.isNotEmpty) {
            final withGrades =
                grades.where((g) => g.transmutedGrade != null).toList();
            if (withGrades.isNotEmpty) {
              withGrades.sort(
                  (a, b) => b.gradingPeriodNumber.compareTo(a.gradingPeriodNumber));
              _selectedQuarter = withGrades.first.gradingPeriodNumber;
            }
          }
          _loadQuarterDetail();
        }
      },
    );
  }

  Future<void> _loadQuarterDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items = [];
      _config = null;
      _currentQuarterGrade = null;
    });

    final qg = _quarterlyGrades
        .where((g) => g.gradingPeriodNumber == _selectedQuarter)
        .toList();
    if (qg.isNotEmpty) _currentQuarterGrade = qg.first;

    final result = await sl<GetMyGradeDetail>()(
      classId: widget.classId,
      gradingPeriodNumber: _selectedQuarter,
    );

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = AppErrorMapper.fromFailure(failure);
          });
        }
      },
      (data) {
        if (mounted) {
          _parseDetailResponse(data);
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _parseDetailResponse(Map<String, dynamic> data) {
    final qgMap = data['quarterly_grade'] as Map<String, dynamic>?;
    if (qgMap != null) {
      _currentQuarterGrade = PeriodGrade(
        id: qgMap['id']?.toString() ?? '',
        classId: qgMap['class_id']?.toString() ?? widget.classId,
        studentId: qgMap['student_id']?.toString() ?? '',
        gradingPeriodNumber:
            (qgMap['quarter'] as num?)?.toInt() ?? _selectedQuarter,
        initialGrade: (qgMap['initial_grade'] as num?)?.toDouble(),
        transmutedGrade: (qgMap['transmuted_grade'] as num?)?.toInt(),
        isLocked: qgMap['is_locked'] == true || qgMap['is_locked'] == 1,
        computedAt: qgMap['computed_at'] != null
            ? DateTime.parse(qgMap['computed_at'] as String)
            : null,
        isPreview: false,
      );
    }

    final itemsList = data['items'] as List<dynamic>? ?? [];
    _items = itemsList.map((item) {
      final m = item as Map<String, dynamic>;
      return GradeItemDetail(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        component: m['component']?.toString() ?? '',
        totalPoints: (m['total_points'] as num?)?.toDouble() ?? 0,
        score: (m['score'] as num?)?.toDouble(),
        effectiveScore: (m['effective_score'] as num?)?.toDouble(),
      );
    }).toList();

    final configMap = data['config'] as Map<String, dynamic>?;
    if (configMap != null) {
      _config = GradingConfig(
        wwWeight: (configMap['ww_weight'] as num?)?.toDouble() ?? 30,
        ptWeight: (configMap['pt_weight'] as num?)?.toDouble() ?? 50,
        qaWeight: (configMap['qa_weight'] as num?)?.toDouble() ?? 20,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassSectionHeader(title: widget.className, showBackButton: true),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadPeriodGrades(),
                color: AppColors.accentCharcoal,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentCharcoal,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _error != null
                        ? _buildErrorState()
                        : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final qg = _currentQuarterGrade;
    final hasGrade = qg?.transmutedGrade != null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),
        OverallGradeBanner(quarterGrade: qg),
        const SizedBox(height: 20),
        QuarterSelector(
          selectedQuarter: _selectedQuarter,
          quarterlyGrades: _quarterlyGrades,
          onChanged: (quarter) {
            setState(() => _selectedQuarter = quarter);
            _loadQuarterDetail();
          },
        ),
        const SizedBox(height: 20),
        if (hasGrade && _items.isNotEmpty) ...[
          GradeComponentSection(
            title: 'Written Works',
            component: 'written_work',
            weight: _config?.wwWeight ?? 30,
            items: _items,
          ),
          const SizedBox(height: 14),
          GradeComponentSection(
            title: 'Performance Tasks',
            component: 'performance_task',
            weight: _config?.ptWeight ?? 50,
            items: _items,
          ),
          const SizedBox(height: 14),
          GradeComponentSection(
            title: 'Quarterly Assessment',
            component: 'quarterly_assessment',
            weight: _config?.qaWeight ?? 20,
            items: _items,
          ),
          const SizedBox(height: 20),
          GradeSummarySection(quarterGrade: qg!),
        ] else if (!hasGrade) ...[
          _buildEmptyQuarterState(),
        ],
        FinalGradeSection(quarterlyGrades: _quarterlyGrades),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.foregroundLight),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.foregroundTertiary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPeriodGrades,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.accentCharcoal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuarterState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: AppColors.foregroundLight),
          SizedBox(height: 12),
          Text(
            'No grades for this quarter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Grades will appear here once computed by your teacher',
            style: TextStyle(fontSize: 12, color: AppColors.foregroundLight),
          ),
        ],
      ),
    );
  }
}
