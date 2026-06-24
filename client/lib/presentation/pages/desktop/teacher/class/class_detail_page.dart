import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_navigation_rail.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assessment/assessments_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/assignment/assignments_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/class/class_overview_panel.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/grades_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/material/materials_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/grade/sf9_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/learner_details_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/attendance_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/core_values_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/sf10_section.dart';
import 'package:likha/presentation/widgets/desktop/teacher/class/student_data_table.dart';
import 'package:likha/presentation/widgets/desktop/teacher/tos/tos_section.dart';
import 'package:likha/domain/classes/entities/class_entity.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/assessment/assessment_list_notifier.dart';
import 'package:likha/presentation/providers/assignment/assignment_list_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/providers/tos_provider.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

class TeacherClassDetailPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherClassDetailPage> createState() =>
      _TeacherClassDetailPageState();
}

class _TeacherClassDetailPageState
    extends ConsumerState<TeacherClassDetailPage> {
  int _selectedIndex = 0;
  Set<int> _loadedTabs = {0};

  static const _baseSectionTitles = [
    'Students',
    'Assessments',
    'Assignments',
    'Materials',
    'TOS',
  ];

  static const _advisorySectionTitles = [
    'Students',
    'Learner Details',
    'Attendance',
    'Core Values',
    'SF9',
    'SF10',
  ];

  static const _baseDestinations = [
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

  static const _advisoryDestinations = [
    DesktopNavDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Students',
    ),
    DesktopNavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Learner Details',
    ),
    DesktopNavDestination(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      label: 'Attendance',
    ),
    DesktopNavDestination(
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite_rounded,
      label: 'Core Values',
    ),
    DesktopNavDestination(
      icon: Icons.grade_outlined,
      selectedIcon: Icons.grade_rounded,
      label: 'SF9',
    ),
    DesktopNavDestination(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
      label: 'SF10',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classDetailProvider.notifier).loadClassDetail(widget.classId);
    });
  }

  @override
  void didUpdateWidget(TeacherClassDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      setState(() {
        _selectedIndex = 0;
        _loadedTabs = {0};
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(classDetailProvider.notifier).loadClassDetail(widget.classId);
      });
    }
  }

  void _onSectionChanged(int index, {bool isAdvisory = false}) {
    setState(() => _selectedIndex = index);

    if (_loadedTabs.contains(index)) return;
    _loadedTabs.add(index);

    if (isAdvisory) {
      switch (index) {
        case 0:
          // Students tab
          break;
        case 1:
          // Learner Details tab
          break;
        case 2:
          // Attendance tab
          break;
        case 3:
          // Core Values tab
          break;
        case 4:
          // SF9 tab
          ref.read(generalAveragesProvider.notifier).loadStudents(widget.classId);
          break;
        case 5:
          // SF10 tab
          ref.read(generalAveragesProvider.notifier).loadStudents(widget.classId);
          break;
      }
    } else {
      switch (index) {
        case 1:
          ref
              .read(assessmentListProvider.notifier)
              .loadAssessments(widget.classId);
          break;
        case 2:
          ref
              .read(assignmentListProvider.notifier)
              .loadAssignments(widget.classId);
          break;
        case 3:
          ref
              .read(learningMaterialProvider.notifier)
              .loadMaterials(widget.classId);
          break;
        case 4:
          ref.read(tosProvider.notifier).loadTosList(widget.classId);
          break;
        case 5:
          // Grades tab
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classDetailState = ref.watch(classDetailProvider);
    final classListState = ref.watch(classListProvider);
    final detail = classDetailState.currentClassDetail;

    final classEntity = classListState.classes
        .cast<ClassEntity?>()
        .firstWhere(
          (c) => c?.id == widget.classId,
          orElse: () => null,
        );
    final isAdvisory = classEntity?.isAdvisory == true;

    // Build dynamic destinations list
    final destinations = isAdvisory
        ? [..._advisoryDestinations]
        : [..._baseDestinations, const DesktopNavDestination(
            icon: Icons.grading_outlined,
            selectedIcon: Icons.grading_rounded,
            label: 'Grades',
          )];

    // Clamp selected index to valid range in case isAdvisory flips while on SF9 tab
    final maxIndex = destinations.length - 1;
    final selectedIndex = _selectedIndex.clamp(0, maxIndex);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Row(
        children: [
          // Left panel
          DesktopNavigationRail(
            selectedIndex: selectedIndex,
            destinations: destinations,
            onDestinationSelected: (index) => _onSectionChanged(index, isAdvisory: isAdvisory),
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
                    index: selectedIndex,
                    children: isAdvisory
                        ? [
                            // Students (with overview panel above)
                            DesktopPageScaffold(
                              title: _advisorySectionTitles[0],
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClassOverviewPanel(
                                    detail: detail,
                                    classEntity: classEntity,
                                  ),
                                  const SizedBox(height: 24),
                                  StudentDataTable(
                                    students: detail.students,
                                  ),
                                ],
                              ),
                            ),
                            // Learner Details
                            LearnerDetailsSection(classId: widget.classId, students: detail.students),
                            // Attendance
                            AttendanceSection(classId: widget.classId, students: detail.students, schoolYear: detail.schoolYear),
                            // Core Values
                            CoreValuesSection(classId: widget.classId, students: detail.students, schoolYear: detail.schoolYear),
                            // SF9
                            Sf9Section(classId: widget.classId),
                            // SF10
                            Sf10Section(classId: widget.classId),
                          ]
                        : [
                            // Students (with overview panel above)
                            DesktopPageScaffold(
                              title: _baseSectionTitles[0],
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClassOverviewPanel(
                                    detail: detail,
                                    classEntity: classEntity,
                                  ),
                                  const SizedBox(height: 24),
                                  StudentDataTable(
                                    students: detail.students,
                                  ),
                                ],
                              ),
                            ),
                            // Assessments
                            AssessmentsSection(classId: widget.classId),
                            // Assignments
                            AssignmentsSection(classId: widget.classId),
                            // Materials
                            MaterialsSection(classId: widget.classId),
                            // TOS
                            TosSection(classId: widget.classId),
                            // Grades
                            GradesSection(
                              classId: widget.classId,
                              isActive: selectedIndex == 5,
                            ),
                          ],
                  ),
          ),
        ],
      ),
    );
  }
}
