import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/entities/quarterly_grade.dart';
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

  List<QuarterlyGrade> _quarterlyGrades = [];
  QuarterlyGrade? _currentQuarterGrade;
  List<_GradeItemDetail> _items = [];
  _GradingConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuarterlyGrades();
    });
  }

  Future<void> _loadQuarterlyGrades() async {
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
          // Default to the most recent quarter with data, or Q1
          if (grades.isNotEmpty) {
            final withGrades =
                grades.where((g) => g.transmutedGrade != null).toList();
            if (withGrades.isNotEmpty) {
              withGrades.sort((a, b) => b.quarter.compareTo(a.quarter));
              _selectedQuarter = withGrades.first.quarter;
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
        .where((g) => g.quarter == _selectedQuarter)
        .toList();
    if (qg.isNotEmpty) {
      _currentQuarterGrade = qg.first;
    }

    final result = await sl<GetMyGradeDetail>()(
      classId: widget.classId,
      quarter: _selectedQuarter,
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
      _currentQuarterGrade = QuarterlyGrade(
        id: qgMap['id']?.toString() ?? '',
        classId: qgMap['class_id']?.toString() ?? widget.classId,
        studentId: qgMap['student_id']?.toString() ?? '',
        quarter: (qgMap['quarter'] as num?)?.toInt() ?? _selectedQuarter,
        wwPercentage: (qgMap['ww_percentage'] as num?)?.toDouble(),
        ptPercentage: (qgMap['pt_percentage'] as num?)?.toDouble(),
        qaPercentage: (qgMap['qa_percentage'] as num?)?.toDouble(),
        wwWeighted: (qgMap['ww_weighted'] as num?)?.toDouble(),
        ptWeighted: (qgMap['pt_weighted'] as num?)?.toDouble(),
        qaWeighted: (qgMap['qa_weighted'] as num?)?.toDouble(),
        initialGrade: (qgMap['initial_grade'] as num?)?.toDouble(),
        transmutedGrade: (qgMap['transmuted_grade'] as num?)?.toInt(),
        isComplete: qgMap['is_complete'] == true ||
            qgMap['is_complete'] == 1,
        computedAt: qgMap['computed_at']?.toString(),
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
      backgroundColor: const Color(0xFFFAFAFA),
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
                  await _loadQuarterlyGrades();
                },
                color: const Color(0xFF2B2B2B),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2B2B2B),
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
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadQuarterlyGrades,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF2B2B2B),
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
            qg?.wwPercentage,
            qg?.wwWeighted,
          ),
          const SizedBox(height: 14),
          _buildComponentSection(
            'Performance Tasks',
            'performance_task',
            _config?.ptWeight ?? 50,
            qg?.ptPercentage,
            qg?.ptWeighted,
          ),
          const SizedBox(height: 14),
          _buildComponentSection(
            'Quarterly Assessment',
            'quarterly_assessment',
            _config?.qaWeight ?? 20,
            qg?.qaPercentage,
            qg?.qaWeighted,
          ),
          const SizedBox(height: 20),

          // Summary row
          _buildSummarySection(qg!),
        ] else if (!hasGrade) ...[
          _buildEmptyQuarterState(),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallGradeBanner(QuarterlyGrade? qg) {
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
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descriptor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildQuarterSelector() {
    return Wrap(
      spacing: 8,
      children: List.generate(4, (index) {
        final quarter = index + 1;
        final isSelected = _selectedQuarter == quarter;
        final hasData = _quarterlyGrades
            .any((g) => g.quarter == quarter && g.transmutedGrade != null);

        return ChoiceChip(
          label: Text('Q$quarter'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected && quarter != _selectedQuarter) {
              setState(() {
                _selectedQuarter = quarter;
              });
              _loadQuarterDetail();
            }
          },
          selectedColor: const Color(0xFF2B2B2B),
          backgroundColor:
              hasData ? const Color(0xFFE8E8E8) : const Color(0xFFF0F0F0),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF666666),
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
        color: const Color(0xFFE0E0E0),
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
                      color: Color(0xFF202020),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${weight.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),

              if (componentItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
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
                                color: Color(0xFF555555),
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
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'No items yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBBBBBB),
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
                      color: Color(0xFF999999),
                    ),
                  ),
                  Text(
                    'Weighted: ${weighted != null ? weighted.toStringAsFixed(1) : '--'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
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

  Widget _buildSummarySection(QuarterlyGrade qg) {
    final transmuted = qg.transmutedGrade ?? 0;
    final descriptor = TransmutationUtil.getDescriptor(transmuted);
    final descriptorColor = TransmutationUtil.getDescriptorColor(transmuted);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
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
                      color: Color(0xFF999999),
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
            color: Color(0xFF999999),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: const Color(0xFF2B2B2B),
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
            color: Color(0xFFCCCCCC),
          ),
          SizedBox(height: 12),
          Text(
            'No grades for this quarter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Grades will appear here once computed by your teacher',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFBBBBBB),
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
