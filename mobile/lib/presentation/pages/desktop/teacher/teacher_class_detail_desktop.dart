import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_navigation_rail.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_student_list_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assessment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_assignment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_material_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/material_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assessment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/assignment_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/class_overview_panel.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/material_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/widgets/student_data_table.dart';
import 'package:likha/presentation/pages/desktop/teacher/create_tos_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/class_record_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/sf9_detail_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos_detail_desktop.dart';
import 'package:likha/presentation/pages/teacher/class_grading_setup_page.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

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
    return ClassRecordDesktop(classId: classId);
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
