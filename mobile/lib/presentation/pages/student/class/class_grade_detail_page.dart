import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';
import 'package:likha/domain/grading/usecases/get_my_grade_detail.dart';
import 'package:likha/domain/grading/usecases/get_my_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';

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
  List<_GradeItemDetail> _items = [];
  _GradingConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPeriodGrades();
    });
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
          // Default to the most recent gradingPeriodNumber with data, or Q1
          if (grades.isNotEmpty) {
            final withGrades =
                grades.where((g) => g.transmutedGrade != null).toList();
            if (withGrades.isNotEmpty) {
              withGrades.sort((a, b) => b.gradingPeriodNumber.compareTo(a.gradingPeriodNumber));
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

    // Find the quarterly grade for the selected quarter
    final qg = _quarterlyGrades
        .where((g) => g.gradingPeriodNumber == _selectedQuarter)
        .toList();
    if (qg.isNotEmpty) {
      _currentQuarterGrade = qg.first;
    }

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
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  void _parseDetailResponse(Map<String, dynamic> data) {
    // Parse quarterly_grade if present (overrides the one from getMyGrades)
    final qgMap = data['quarterly_grade'] as Map<String, dynamic>?;
    if (qgMap != null) {
      _currentQuarterGrade = PeriodGrade(
        id: qgMap['id']?.toString() ?? '',
        classId: qgMap['class_id']?.toString() ?? widget.classId,
        studentId: qgMap['student_id']?.toString() ?? '',
        gradingPeriodNumber: (qgMap['quarter'] as num?)?.toInt() ?? _selectedQuarter,
        initialGrade: (qgMap['initial_grade'] as num?)?.toDouble(),
        transmutedGrade: (qgMap['transmuted_grade'] as num?)?.toInt(),
        isLocked: qgMap['is_locked'] == true ||
            qgMap['is_locked'] == 1,
        computedAt: qgMap['computed_at'] != null ? DateTime.parse(qgMap['computed_at'] as String) : null,
        isPreview: false,
      );
    }

    // Parse items
    final itemsList = data['items'] as List<dynamic>? ?? [];
    _items = itemsList.map((item) {
      final m = item as Map<String, dynamic>;
      return _GradeItemDetail(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        component: m['component']?.toString() ?? '',
        totalPoints: (m['total_points'] as num?)?.toDouble() ?? 0,
        score: (m['score'] as num?)?.toDouble(),
        effectiveScore: (m['effective_score'] as num?)?.toDouble(),
      );
    }).toList();

    // Parse config
    final configMap = data['config'] as Map<String, dynamic>?;
    if (configMap != null) {
      _config = _GradingConfig(
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
            ClassSectionHeader(
              title: widget.className,
              showBackButton: true,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadPeriodGrades();
                },
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.foregroundLight,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundTertiary,
              ),
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

  Widget _buildContent() {
    final qg = _currentQuarterGrade;
    final hasGrade = qg?.transmutedGrade != null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),

        // Overall grade banner
        _buildOverallGradeBanner(qg),

        const SizedBox(height: 20),

        // Quarter selector
        _buildQuarterSelector(),

        const SizedBox(height: 20),

        // Component sections
        if (hasGrade && _items.isNotEmpty) ...[
          _buildComponentSection(
            'Written Works',
            'written_work',
            _config?.wwWeight ?? 30,
            null, // percentage not available in new schema
            null, // weighted not available in new schema
          ),
          const SizedBox(height: 14),
          _buildComponentSection(
            'Performance Tasks',
            'performance_task',
            _config?.ptWeight ?? 50,
            null, // percentage not available in new schema
            null, // weighted not available in new schema
          ),
          const SizedBox(height: 14),
          _buildComponentSection(
            'Quarterly Assessment',
            'quarterly_assessment',
            _config?.qaWeight ?? 20,
            null, // percentage not available in new schema
            null, // weighted not available in new schema
          ),
          const SizedBox(height: 20),

          // Summary row
          _buildSummarySection(qg!),
        ] else if (!hasGrade) ...[
          _buildEmptyQuarterState(),
        ],

        // Final Grade section (shown when at least 2 quarters have grades)
        _buildFinalGradeSection(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallGradeBanner(PeriodGrade? qg) {
    final hasGrade = qg?.transmutedGrade != null;
    final gradeDisplay = hasGrade ? '${qg!.transmutedGrade}' : '--';
    final descriptor = hasGrade
        ? TransmutationUtil.getDescriptor(qg!.transmutedGrade!)
        : 'No grade yet';

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          gradeDisplay,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descriptor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuarterSelector() {
    return Wrap(
      spacing: 8,
      children: List.generate(4, (index) {
        final gradingPeriodNumber = index + 1;
        final isSelected = _selectedQuarter == gradingPeriodNumber;
        final hasData = _quarterlyGrades
            .any((g) => g.gradingPeriodNumber == gradingPeriodNumber && g.transmutedGrade != null);

        return ChoiceChip(
          label: Text('Q$gradingPeriodNumber'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected && gradingPeriodNumber != _selectedQuarter) {
              setState(() {
                _selectedQuarter = gradingPeriodNumber;
              });
              _loadQuarterDetail();
            }
          },
          selectedColor: AppColors.accentCharcoal,
          backgroundColor:
              hasData ? AppColors.borderLight : AppColors.backgroundTertiary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.foregroundSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide.none,
          showCheckmark: false,
        );
      }),
    );
  }

  Widget _buildComponentSection(
    String title,
    String component,
    double weight,
    double? percentage,
    double? weighted,
  ) {
    final componentItems =
        _items.where((i) => i.component == component).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${weight.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              if (componentItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderLight,),
                const SizedBox(height: 8),

                // Individual items
                ...componentItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.foregroundSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.effectiveScore != null
                                ? '${_formatNum(item.effectiveScore!)}/${_formatNum(item.totalPoints)}'
                                : '--/${_formatNum(item.totalPoints)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentCharcoal,
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.borderLight,),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'No items yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Percentage and weighted score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Percentage: ${percentage != null ? '${percentage.toStringAsFixed(1)}%' : '--'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                  Text(
                    'Weighted: ${weighted != null ? weighted.toStringAsFixed(1) : '--'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(PeriodGrade qg) {
    final transmuted = qg.transmutedGrade ?? 0;
    final descriptor = TransmutationUtil.getDescriptor(transmuted);
    final descriptorColor = TransmutationUtil.getDescriptorColor(transmuted);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow(
                'Initial Grade',
                qg.initialGrade != null
                    ? qg.initialGrade!.toStringAsFixed(1)
                    : '--',
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Transmuted Grade',
                '$transmuted',
                isBold: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Descriptor',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(descriptorColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      descriptor,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.accentCharcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalGradeSection() {
    final withGrades = _quarterlyGrades
        .where((g) => g.transmutedGrade != null)
        .toList();

    if (withGrades.length < 2) return const SizedBox.shrink();

    final sum =
        withGrades.fold<int>(0, (acc, g) => acc + g.transmutedGrade!);
    final finalGrade =
        double.parse((sum / withGrades.length).toStringAsFixed(1));
    final finalGradeRounded = finalGrade.round();
    final descriptor = TransmutationUtil.getDescriptor(finalGradeRounded);
    final descriptorColor =
        TransmutationUtil.getDescriptorColor(finalGradeRounded);

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Final Grade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foregroundDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$finalGradeRounded',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCharcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(descriptorColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      descriptor,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyQuarterState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColors.foregroundLight,
          ),
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foregroundLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

// Internal model for parsed grade item detail from the API response
class _GradeItemDetail {
  final String id;
  final String title;
  final String component;
  final double totalPoints;
  final double? score;
  final double? effectiveScore;

  _GradeItemDetail({
    required this.id,
    required this.title,
    required this.component,
    required this.totalPoints,
    this.score,
    this.effectiveScore,
  });
}

// Internal model for parsed grading config from the API response
class _GradingConfig {
  final double wwWeight;
  final double ptWeight;
  final double qaWeight;

  _GradingConfig({
    required this.wwWeight,
    required this.ptWeight,
    required this.qaWeight,
  });
}
