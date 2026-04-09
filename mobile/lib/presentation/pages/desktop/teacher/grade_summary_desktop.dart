import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/grading/usecases/get_final_grades.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/general_average_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

class GradeSummaryDesktop extends ConsumerStatefulWidget {
  final String classId;
  final int initialQuarter;

  const GradeSummaryDesktop({
    super.key,
    required this.classId,
    this.initialQuarter = 1,
  });

  @override
  ConsumerState<GradeSummaryDesktop> createState() =>
      _GradeSummaryDesktopState();
}

class _GradeSummaryDesktopState extends ConsumerState<GradeSummaryDesktop>
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
      _loadQuarterlyData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _qgEditController.dispose();
    _qgFocusNode.dispose();
    super.dispose();
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
      ref.read(quarterlyGradesProvider.notifier).updateQuarterlyGrade(
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

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      _loadFinalGradesIfNeeded();
    }
  }

  void _loadQuarterlyData() {
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedQuarter);
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
          if (mounted) {
            setState(() {
              _finalGradesLoading = false;
              _finalGradesError = failure.message;
            });
          }
        },
        (grades) {
          if (mounted) {
            setState(() {
              _finalGrades = grades;
              _finalGradesLoading = false;
            });
          }
        },
      );

      ref
          .read(generalAverageProvider.notifier)
          .loadGeneralAverages(widget.classId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _finalGradesLoading = false;
          _finalGradesError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _buildQuarterSelector(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuarterlyTab(),
                  _buildFinalGradesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterSelector() {
    return Row(
      children: List.generate(4, (index) {
        final quarter = index + 1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('Q$quarter'),
            selected: _selectedQuarter == quarter,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedQuarter = quarter);
                _loadQuarterlyData();
              }
            },
            selectedColor: AppColors.foregroundDark,
            labelStyle: TextStyle(
              color: _selectedQuarter == quarter
                  ? Colors.white
                  : AppColors.foregroundPrimary,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.borderLight),
          ),
        );
      }),
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
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Quarterly'),
          Tab(text: 'Final Grades'),
        ],
      ),
    );
  }

  Widget _buildQuarterlyTab() {
    final state = ref.watch(quarterlyGradesProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(color: AppColors.semanticError),
        ),
      );
    }

    final summary = state.summary;
    if (summary == null || summary.isEmpty) {
      return const Center(
        child: Text(
          'No quarterly grades available.',
          style: TextStyle(color: AppColors.foregroundSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppColors.backgroundTertiary),
              columnSpacing: 24,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 160,
                    child: Text(
                      'Student',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text('WW%',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('PT%',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('QA%',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('QG',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Descriptor',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
              rows: List.generate(summary.length, (index) {
                final row = summary[index];
                final qg = (row['quarterly_grade'] as num?)?.toInt();
                final studentId = row['student_id']?.toString() ?? '';
                final isEven = index % 2 == 0;
                final isEditingQg = _editingStudentId == studentId;

                return DataRow(
                  color: WidgetStateProperty.all(
                    isEven ? Colors.white : AppColors.backgroundSecondary,
                  ),
                  cells: [
                    DataCell(SizedBox(
                      width: 160,
                      child: Text(
                        row['student_name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(
                      _formatScore(row['ww_weighted_score']),
                      textAlign: TextAlign.right,
                    )),
                    DataCell(Text(
                      _formatScore(row['pt_weighted_score']),
                      textAlign: TextAlign.right,
                    )),
                    DataCell(Text(
                      _formatScore(row['qa_weighted_score']),
                      textAlign: TextAlign.right,
                    )),
                    DataCell(
                      isEditingQg
                          ? SizedBox(
                              width: 56,
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
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                            )
                          : GestureDetector(
                              onTap: () =>
                                  _startQgEdit(studentId, qg),
                              child: Text(
                                qg?.toString() ?? '-',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: qg != null && qg >= 75
                                      ? AppColors.foregroundDark
                                      : AppColors.semanticError,
                                ),
                              ),
                            ),
                    ),
                    DataCell(_buildDescriptorBadge(qg)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsFooter(summary),
        ],
      ),
    );
  }

  Widget _buildStatsFooter(List<Map<String, dynamic>> summary) {
    final grades = summary
        .map((r) => (r['quarterly_grade'] as num?)?.toInt())
        .where((g) => g != null)
        .cast<int>()
        .toList();

    if (grades.isEmpty) {
      return const SizedBox.shrink();
    }

    final average = grades.reduce((a, b) => a + b) / grades.length;
    final highest = grades.reduce((a, b) => a > b ? a : b);
    final lowest = grades.reduce((a, b) => a < b ? a : b);
    final passCount = grades.where((g) => g >= 75).length;
    final passRate = (passCount / grades.length * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Average', average.toStringAsFixed(1)),
          _buildStatItem('Highest', highest.toString()),
          _buildStatItem('Lowest', lowest.toString()),
          _buildStatItem('Pass Rate', '$passRate%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.foregroundSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalGradesTab() {
    if (_finalGradesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_finalGradesError != null) {
      return Center(
        child: Text(
          _finalGradesError!,
          style: const TextStyle(color: AppColors.semanticError),
        ),
      );
    }

    if (_finalGrades == null || _finalGrades!.isEmpty) {
      return const Center(
        child: Text(
          'No final grades available.',
          style: TextStyle(color: AppColors.foregroundSecondary),
        ),
      );
    }

    final gaState = ref.watch(generalAverageProvider);

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppColors.backgroundTertiary),
          columnSpacing: 24,
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 160,
                child: Text(
                  'Student',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            DataColumn(
              label: Text('Q1', style: TextStyle(fontWeight: FontWeight.w700)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Q2', style: TextStyle(fontWeight: FontWeight.w700)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Q3', style: TextStyle(fontWeight: FontWeight.w700)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Q4', style: TextStyle(fontWeight: FontWeight.w700)),
              numeric: true,
            ),
            DataColumn(
              label:
                  Text('Final', style: TextStyle(fontWeight: FontWeight.w700)),
              numeric: true,
            ),
            DataColumn(
              label: Text('GA', style: TextStyle(fontWeight: FontWeight.w700)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Descriptor',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
          rows: List.generate(_finalGrades!.length, (index) {
            final row = _finalGrades![index];
            final q1 = (row['q1'] as num?)?.toInt();
            final q2 = (row['q2'] as num?)?.toInt();
            final q3 = (row['q3'] as num?)?.toInt();
            final q4 = (row['q4'] as num?)?.toInt();
            final quarters = [q1, q2, q3, q4].whereType<int>().toList();
            final finalGrade = quarters.isNotEmpty
                ? (quarters.reduce((a, b) => a + b) / quarters.length).round()
                : null;

            final studentId = row['student_id']?.toString();
            int? ga;
            if (gaState.response != null && studentId != null) {
              final studentGA = gaState.response!.students
                  .where((s) => s.studentId == studentId)
                  .toList();
              if (studentGA.isNotEmpty) {
                ga = studentGA.first.generalAverage;
              }
            }

            final gradeForDescriptor = finalGrade;
            final isEven = index % 2 == 0;

            return DataRow(
              color: WidgetStateProperty.all(
                isEven ? Colors.white : AppColors.backgroundSecondary,
              ),
              cells: [
                DataCell(SizedBox(
                  width: 160,
                  child: Text(
                    row['student_name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Text(q1?.toString() ?? '-',
                    textAlign: TextAlign.right)),
                DataCell(Text(q2?.toString() ?? '-',
                    textAlign: TextAlign.right)),
                DataCell(Text(q3?.toString() ?? '-',
                    textAlign: TextAlign.right)),
                DataCell(Text(q4?.toString() ?? '-',
                    textAlign: TextAlign.right)),
                DataCell(Text(
                  finalGrade?.toString() ?? '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: finalGrade != null && finalGrade >= 75
                        ? AppColors.foregroundDark
                        : AppColors.semanticError,
                  ),
                )),
                DataCell(Text(
                  ga?.toString() ?? '-',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )),
                DataCell(_buildDescriptorBadge(gradeForDescriptor)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDescriptorBadge(int? grade) {
    if (grade == null) {
      return const Text('-', style: TextStyle(color: AppColors.foregroundLight));
    }

    final descriptor = TransmutationUtil.getDescriptor(grade);
    final colorValue = TransmutationUtil.getDescriptorColor(grade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(colorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        descriptor,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(colorValue),
        ),
      ),
    );
  }

  String _formatScore(dynamic value) {
    if (value == null) return '-';
    if (value is num) return value.toStringAsFixed(1);
    return value.toString();
  }
}
