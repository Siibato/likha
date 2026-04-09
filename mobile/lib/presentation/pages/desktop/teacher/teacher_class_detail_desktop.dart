import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_navigation_rail.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_grading_setup_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_student_list_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assessment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assignment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_material_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/grade_summary_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/material_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assessment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assignment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/class_overview_panel.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/grade_spreadsheet.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/material_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/student_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_tos_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/sf9_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos_detail_desktop.dart';
import 'package:likha/presentation/pages/teacher/class_grading_setup_page.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/widgets/styled_dialog.dart';

class TeacherClassDetailDesktop extends ConsumerStatefulWidget {
  final String classId;

  const TeacherClassDetailDesktop({super.key, required this.classId});

  @override
  ConsumerState<TeacherClassDetailDesktop> createState() =>
      _TeacherClassDetailDesktopState();
}

class _TeacherClassDetailDesktopState
    extends ConsumerState<TeacherClassDetailDesktop> {
  int _selectedIndex = 0;
  final Set<int> _loadedTabs = {0};

  static const _baseSectionTitles = [
    'Overview',
    'Students',
    'Assessments',
    'Assignments',
    'Materials',
    'TOS',
  ];

  static const _baseDestinations = [
    DesktopNavDestination(
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
      label: 'Overview',
    ),
    DesktopNavDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Students',
    ),
    DesktopNavDestination(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Assessments',
    ),
    DesktopNavDestination(
      icon: Icons.task_outlined,
      selectedIcon: Icons.task_rounded,
      label: 'Assignments',
    ),
    DesktopNavDestination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Materials',
    ),
    DesktopNavDestination(
      icon: Icons.table_chart_outlined,
      selectedIcon: Icons.table_chart_rounded,
      label: 'TOS',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  void _onSectionChanged(int index) {
    setState(() => _selectedIndex = index);

    if (_loadedTabs.contains(index)) return;
    _loadedTabs.add(index);

    switch (index) {
      case 2:
        ref
            .read(teacherAssessmentProvider.notifier)
            .loadAssessments(widget.classId);
        break;
      case 3:
        ref
            .read(assignmentProvider.notifier)
            .loadAssignments(widget.classId);
        break;
      case 4:
        ref
            .read(learningMaterialProvider.notifier)
            .loadMaterials(widget.classId);
        break;
      case 5:
        ref.read(tosProvider.notifier).loadTosList(widget.classId);
        break;
      case 6:
        // index 6 is either Grades (non-advisory) or SF9 (advisory)
        final classState = ref.read(classProvider);
        final classEntity = classState.classes.cast<dynamic>().firstWhere(
              (c) => c?.id == widget.classId,
              orElse: () => null,
            );
        final isAdvisory = classEntity?.isAdvisory == true;
        if (isAdvisory) {
          ref.read(sf9Provider.notifier).loadStudents(widget.classId);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final detail = classState.currentClassDetail;

    final classEntity = classState.classes.cast<dynamic>().firstWhere(
          (c) => c?.id == widget.classId,
          orElse: () => null,
        );
    final isAdvisory = classEntity?.isAdvisory == true;

    // Build dynamic destinations list
    final lastDestination = isAdvisory
        ? const DesktopNavDestination(
            icon: Icons.grade_outlined,
            selectedIcon: Icons.grade_rounded,
            label: 'SF9',
          )
        : const DesktopNavDestination(
            icon: Icons.grading_outlined,
            selectedIcon: Icons.grading_rounded,
            label: 'Grades',
          );
    final destinations = [..._baseDestinations, lastDestination];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Row(
        children: [
          // Left panel
          DesktopNavigationRail(
            selectedIndex: _selectedIndex,
            destinations: destinations,
            onDestinationSelected: _onSectionChanged,
            header: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    color: AppColors.foregroundPrimary,
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back to classes',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      detail?.title ?? 'Class',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foregroundDark,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.borderLight,
          ),

          // Content area
          Expanded(
            child: detail == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // Overview
                      DesktopPageScaffold(
                        title: _baseSectionTitles[0],
                        body: ClassOverviewPanel(
                          detail: detail,
                          classEntity: classEntity,
                          onViewStudents: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassStudentListDesktop(
                                  classId: widget.classId),
                            ),
                          ),
                          onGradingSetup: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassGradingSetupPage(
                                  classId: widget.classId),
                            ),
                          ),
                        ),
                      ),

                      // Students
                      DesktopPageScaffold(
                        title: _baseSectionTitles[1],
                        body: StudentDataTable(
                          students: detail.students,
                        ),
                      ),

                      // Assessments
                      _AssessmentsSection(classId: widget.classId),

                      // Assignments
                      _AssignmentsSection(classId: widget.classId),

                      // Materials
                      _MaterialsSection(classId: widget.classId),

                      // TOS
                      _TosSection(classId: widget.classId),

                      // Grades (non-advisory) or SF9 (advisory)
                      if (isAdvisory)
                        _Sf9Section(classId: widget.classId)
                      else
                        _GradesSection(classId: widget.classId),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Section widgets (each wraps content in DesktopPageScaffold) ---

class _AssessmentsSection extends ConsumerWidget {
  final String classId;

  const _AssessmentsSection({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherAssessmentProvider);

    return DesktopPageScaffold(
      title: 'Assessments',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAssessmentDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadAssessments(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Assessment'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.assessments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : AssessmentDataTable(
              assessments: state.assessments,
              onTap: (assessment) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssessmentDetailDesktop(assessmentId: assessment.id),
                ),
              ).then((_) => ref
                  .read(teacherAssessmentProvider.notifier)
                  .loadAssessments(classId)),
            ),
    );
  }
}

class _AssignmentsSection extends ConsumerWidget {
  final String classId;

  const _AssignmentsSection({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return DesktopPageScaffold(
      title: 'Assignments',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateAssignmentDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref
                  .read(assignmentProvider.notifier)
                  .loadAssignments(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Assignment'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.assignments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : AssignmentDataTable(
              assignments: state.assignments,
              onTap: (assignment) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AssignmentDetailDesktop(assignmentId: assignment.id),
                ),
              ).then((_) => ref
                  .read(assignmentProvider.notifier)
                  .loadAssignments(classId)),
            ),
    );
  }
}

class _MaterialsSection extends ConsumerWidget {
  final String classId;

  const _MaterialsSection({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningMaterialProvider);

    return DesktopPageScaffold(
      title: 'Materials',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateMaterialDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref
                  .read(learningMaterialProvider.notifier)
                  .loadMaterials(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Module'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.materials.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : MaterialDataTable(
              materials: state.materials,
              onTap: (material) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MaterialDetailDesktop(materialId: material.id),
                ),
              ).then((_) => ref
                  .read(learningMaterialProvider.notifier)
                  .loadMaterials(classId)),
            ),
    );
  }
}

class _TosSection extends ConsumerWidget {
  final String classId;

  const _TosSection({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tosProvider);

    return DesktopPageScaffold(
      title: 'Table of Specifications',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateTosDesktop(classId: classId),
            ),
          ).then((result) {
            if (result == true) {
              ref.read(tosProvider.notifier).loadTosList(classId);
            }
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create TOS'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
      body: state.isLoading && state.tosList.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : state.tosList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.table_chart_outlined,
                            size: 48, color: AppColors.borderLight),
                        SizedBox(height: 12),
                        Text(
                          'No TOS created yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.backgroundTertiary),
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(
                            label: Text('Title', style: _headerStyle)),
                        DataColumn(
                            label: Text('Quarter', style: _headerStyle)),
                        DataColumn(
                            label: Text('Mode', style: _headerStyle)),
                        DataColumn(
                            label: Text('Items', style: _headerStyle),
                            numeric: true),
                      ],
                      rows: state.tosList.map((tos) {
                        return DataRow(
                          onSelectChanged: (_) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TosDetailDesktop(
                                tosId: tos.id,
                                classId: classId,
                              ),
                            ),
                          ).then((_) => ref
                              .read(tosProvider.notifier)
                              .loadTosList(classId)),
                          cells: [
                            DataCell(Text(
                              tos.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foregroundDark,
                              ),
                            )),
                            DataCell(Text(
                              'Q${tos.quarter}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            )),
                            DataCell(Text(
                              tos.classificationMode == 'blooms'
                                  ? "Bloom's"
                                  : 'Difficulty',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.foregroundTertiary,
                              ),
                            )),
                            DataCell(Text(
                              '${tos.totalItems}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.foregroundSecondary,
                              ),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}

class _GradesSection extends StatelessWidget {
  final String classId;

  const _GradesSection({required this.classId});

  @override
  Widget build(BuildContext context) {
    return _GradesTabContent(classId: classId);
  }
}

// ── Inline Grades tab content ────────────────────────────────────────────────

class _GradesTabContent extends ConsumerStatefulWidget {
  final String classId;

  const _GradesTabContent({required this.classId});

  @override
  ConsumerState<_GradesTabContent> createState() => _GradesTabContentState();
}

class _GradesTabContentState extends ConsumerState<_GradesTabContent> {
  int _selectedQuarter = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(gradingConfigProvider.notifier)
          .loadConfig(widget.classId);

      final configState = ref.read(gradingConfigProvider);
      if (configState.isConfigured) {
        _loadData();
      }
    });
  }

  void _loadData() {
    // Load ALL components for the selected quarter
    ref.read(gradeItemsProvider.notifier).setQuarter(_selectedQuarter);
    ref.read(gradeItemsProvider.notifier).setComponent('');
    ref.read(gradeItemsProvider.notifier).loadItems(widget.classId);
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedQuarter);
  }

  void _onQuarterChanged(int quarter) {
    setState(() => _selectedQuarter = quarter);
    _loadData();
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddGradeItemDialog(
        classId: widget.classId,
        quarter: _selectedQuarter,
      ),
    );
  }

  void _saveInlineScore(
    String studentId,
    String itemId,
    GradeScore? existingScore,
    double newScore,
  ) {
    if (existingScore != null && existingScore.isAutoPopulated) {
      ref
          .read(gradeScoresProvider.notifier)
          .setOverride(existingScore.id, newScore);
    } else {
      ref.read(gradeScoresProvider.notifier).saveScores(itemId, [
        {'student_id': studentId, 'score': newScore},
      ]);
    }
  }

  void _saveQg(String studentId, int? newQg) {
    if (newQg == null) return;
    ref.read(quarterlyGradesProvider.notifier).updateQuarterlyGrade(
          classId: widget.classId,
          studentId: studentId,
          quarter: _selectedQuarter,
          transmutedGrade: newQg,
        );
  }

  void _computeGrades() async {
    await ref
        .read(quarterlyGradesProvider.notifier)
        .computeGrades(widget.classId, _selectedQuarter);
    if (!mounted) return;
    ref
        .read(quarterlyGradesProvider.notifier)
        .loadSummary(widget.classId, _selectedQuarter);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grades computed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFinalGrades() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradeSummaryDesktop(
          classId: widget.classId,
          initialQuarter: _selectedQuarter,
        ),
      ),
    );
  }

  void _openGradingSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassGradingSetupDesktop(classId: widget.classId),
      ),
    ).then((_) {
      ref.read(gradingConfigProvider.notifier).loadConfig(widget.classId);
      _loadData();
    });
  }

  GradeConfig? _configForQuarter(List<dynamic> configs) {
    for (final c in configs) {
      if ((c as GradeConfig).quarter == _selectedQuarter) return c;
    }
    return configs.isNotEmpty ? configs.first as GradeConfig : null;
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final configState = ref.watch(gradingConfigProvider);
    final itemsState = ref.watch(gradeItemsProvider);
    final scoresState = ref.watch(gradeScoresProvider);
    final gradesState = ref.watch(quarterlyGradesProvider);
    final students = classState.currentClassDetail?.students ?? [];
    final config = _configForQuarter(configState.configs);

    ref.listen<GradeItemsState>(gradeItemsProvider, (prev, next) {
      if (prev?.isLoading == true &&
          !next.isLoading &&
          next.items.isNotEmpty) {
        final itemIds = next.items.map((i) => i.id).toList();
        ref.read(gradeScoresProvider.notifier).loadScoresForItems(itemIds);
      }
    });

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Quarter chips + action buttons
          Row(
            children: [
              ...List.generate(4, (index) {
                final quarter = index + 1;
                final isSelected = _selectedQuarter == quarter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Q$quarter'),
                    selected: isSelected,
                    onSelected: (_) => _onQuarterChanged(quarter),
                    selectedColor: AppColors.foregroundPrimary,
                    backgroundColor: AppColors.backgroundPrimary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.backgroundPrimary
                          : AppColors.foregroundPrimary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.foregroundPrimary
                          : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    showCheckmark: false,
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                onPressed: _openGradingSetup,
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.foregroundSecondary,
                  size: 20,
                ),
                tooltip: 'Grading Setup',
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openFinalGrades,
                icon: const Icon(Icons.grade_outlined, size: 18),
                label: const Text('Final Grades'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foregroundPrimary,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _computeGrades,
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('Compute Grades'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foregroundPrimary,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.foregroundPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Spreadsheet area
          Expanded(
            child: configState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : !configState.isConfigured
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.grading_outlined,
                                size: 48,
                                color: AppColors.foregroundTertiary),
                            const SizedBox(height: 16),
                            const Text(
                              'Grading is not set up for this class yet.',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.foregroundSecondary),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _openGradingSetup,
                              icon: const Icon(Icons.settings_outlined,
                                  size: 18),
                              label: const Text('Set Up Grading'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.foregroundPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : (itemsState.isLoading && itemsState.items.isEmpty) ||
                            scoresState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.foregroundPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : GradeSpreadsheet(
                    students: students,
                    allItems: itemsState.items,
                    scoresByItem: scoresState.scoresByItem,
                    config: config,
                    summary: gradesState.summary,
                    onScoreChanged:
                        (studentId, itemId, existingScore, score) {
                      _saveInlineScore(
                          studentId, itemId, existingScore, score);
                    },
                    onQgChanged: (studentId, newQg) =>
                        _saveQg(studentId, newQg),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddGradeItemDialog extends ConsumerStatefulWidget {
  final String classId;
  final int quarter;

  const _AddGradeItemDialog({
    required this.classId,
    required this.quarter,
  });

  @override
  ConsumerState<_AddGradeItemDialog> createState() =>
      _AddGradeItemDialogState();
}

class _AddGradeItemDialogState extends ConsumerState<_AddGradeItemDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _pointsController;
  String _selectedComponent = 'ww';

  static const _componentKeys = ['ww', 'pt', 'qa'];
  static const _componentLabels = ['Written Works', 'Performance Tasks', 'Quarterly Assessment'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _pointsController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _handleAddItem() {
    final title = _titleController.text.trim();
    final points = double.tryParse(_pointsController.text.trim());
    if (title.isEmpty || points == null || points <= 0) return;

    ref.read(gradeItemsProvider.notifier).createItem(
      widget.classId,
      {
        'title': title,
        'component': _selectedComponent,
        'quarter': widget.quarter,
        'total_points': points,
        'source_type': 'manual',
      },
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'Add Grade Item',
      subtitle: 'Quarter ${widget.quarter}',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Component selector
            Row(
              children: [
                for (int i = 0; i < _componentKeys.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedComponent = _componentKeys[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedComponent == _componentKeys[i]
                              ? AppColors.foregroundPrimary
                              : AppColors.backgroundPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedComponent == _componentKeys[i]
                                ? AppColors.foregroundPrimary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          _componentKeys[i].toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedComponent == _componentKeys[i]
                                ? AppColors.backgroundPrimary
                                : AppColors.foregroundSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _componentLabels[_componentKeys.indexOf(_selectedComponent)],
              style: const TextStyle(
                  fontSize: 12, color: AppColors.foregroundTertiary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pointsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: StyledTextFieldDecoration.styled(
                labelText: 'Total Points',
              ),
            ),
          ],
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialogAction(
          label: 'Add Item',
          isPrimary: true,
          onPressed: _handleAddItem,
        ),
      ],
    );
  }
}

class _Sf9Section extends ConsumerWidget {
  final String classId;

  const _Sf9Section({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sf9Provider);

    return DesktopPageScaffold(
      title: 'SF9',
      body: state.isLoading && state.students.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppColors.foregroundPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                        color: AppColors.semanticError,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : state.students.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 48, color: AppColors.borderLight),
                            SizedBox(height: 12),
                            Text(
                              'No students found',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppColors.backgroundTertiary),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(
                                label: Text('Student Name',
                                    style: _headerStyle)),
                            DataColumn(
                                label: Text('General Average',
                                    style: _headerStyle),
                                numeric: true),
                            DataColumn(
                                label:
                                    Text('Subjects', style: _headerStyle),
                                numeric: true),
                          ],
                          rows: state.students.map((student) {
                            return DataRow(
                              onSelectChanged: (_) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Sf9DetailDesktop(
                                    classId: classId,
                                    studentId: student.studentId,
                                    studentName: student.studentName,
                                  ),
                                ),
                              ),
                              cells: [
                                DataCell(Text(
                                  student.studentName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foregroundDark,
                                  ),
                                )),
                                DataCell(Text(
                                  student.generalAverage?.toString() ?? '--',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.foregroundSecondary,
                                  ),
                                )),
                                DataCell(Text(
                                  '${student.subjectCount}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.foregroundSecondary,
                                  ),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: AppColors.foregroundSecondary,
);
