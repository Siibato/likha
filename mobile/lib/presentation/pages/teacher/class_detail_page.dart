import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/add_student_page.dart';
import 'package:likha/presentation/pages/teacher/assessment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/assignment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/create_assessment_page.dart';
import 'package:likha/presentation/pages/teacher/create_assignment_page.dart';
import 'package:likha/presentation/pages/teacher/create_material_page.dart';
import 'package:likha/presentation/pages/teacher/edit_class_page.dart';
import 'package:likha/presentation/pages/teacher/material_detail_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assessment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assignment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_assessment_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_assignment_card.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';

class ClassDetailPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
      ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final assessmentState = ref.watch(assessmentProvider);
    final assignmentState = ref.watch(assignmentProvider);
    final materialState = ref.watch(learningMaterialProvider);
    final detail = classState.currentClassDetail;

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Text(
          detail?.title ?? 'Class Detail',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2B2B2B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit' && detail != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditClassPage(
                      classId: widget.classId,
                      currentTitle: detail.title,
                      currentDescription: detail.description,
                    ),
                  ),
                ).then((_) => ref.read(classProvider.notifier).loadClassDetail(widget.classId));
              } else if (value == 'add_students') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStudentPage(classId: widget.classId),
                  ),
                ).then((_) => ref.read(classProvider.notifier).loadClassDetail(widget.classId));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 20, color: Color(0xFF2B2B2B)),
                    SizedBox(width: 12),
                    Text('Edit Class', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_students',
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded, size: 20, color: Color(0xFF2B2B2B)),
                    SizedBox(width: 12),
                    Text('Add Students', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2B2B2B),
              unselectedLabelColor: const Color(0xFF999999),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFF2B2B2B),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Assessments'),
                Tab(text: 'Assignments'),
                Tab(text: 'Modules'),
              ],
            ),
          ),
        ),
      ),
      body: detail == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssessmentsTab(assessmentState),
                _buildAssignmentsTab(assignmentState),
                _buildMaterialsTab(materialState),
              ],
            ),
    );
  }

  Widget _buildAssessmentsTab(AssessmentState assessmentState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAssessmentPage(classId: widget.classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref
                        .read(assessmentProvider.notifier)
                        .loadAssessments(widget.classId);
                  }
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: assessmentState.isLoading &&
                  assessmentState.assessments.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                )
              : assessmentState.assessments.isEmpty
                  ? const EmptyAssessmentListState()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(assessmentProvider.notifier)
                          .loadAssessments(widget.classId),
                      color: const Color(0xFF2B2B2B),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: assessmentState.assessments.length,
                        itemBuilder: (context, index) {
                          final assessment =
                              assessmentState.assessments[index];
                          return TeacherAssessmentCard(
                            assessment: assessment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssessmentDetailPage(
                                  assessmentId: assessment.id,
                                ),
                              ),
                            ).then((_) => ref
                                .read(assessmentProvider.notifier)
                                .loadAssessments(widget.classId)),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab(AssignmentState assignmentState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateAssignmentPage(classId: widget.classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref
                        .read(assignmentProvider.notifier)
                        .loadAssignments(widget.classId);
                  }
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: assignmentState.isLoading &&
                  assignmentState.assignments.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B2B2B),
                    strokeWidth: 2.5,
                  ),
                )
              : assignmentState.assignments.isEmpty
                  ? const EmptyAssignmentListState()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(assignmentProvider.notifier)
                          .loadAssignments(widget.classId),
                      color: const Color(0xFF2B2B2B),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: assignmentState.assignments.length,
                        itemBuilder: (context, index) {
                          final assignment =
                              assignmentState.assignments[index];
                          return TeacherAssignmentCard(
                            assignment: assignment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignmentDetailPage(
                                  assignmentId: assignment.id,
                                ),
                              ),
                            ).then((_) => ref
                                .read(assignmentProvider.notifier)
                                .loadAssignments(widget.classId)),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTab(LearningMaterialState materialState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateMaterialPage(classId: widget.classId),
                  ),
                ).then((result) {
                  if (result == true) {
                    ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId);
                  }
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B2B2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: materialState.isLoading && materialState.materials.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B2B2B), strokeWidth: 2.5))
              : materialState.materials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.library_books_outlined, size: 64, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 16),
                          Text('No modules yet', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(learningMaterialProvider.notifier).loadMaterials(widget.classId),
                      color: const Color(0xFF2B2B2B),
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: materialState.materials.length,
                        onReorder: (oldIndex, newIndex) {
                          final material = materialState.materials[oldIndex];
                          ref.read(learningMaterialProvider.notifier).reorderMaterial(
                                material.id,
                                newIndex > oldIndex ? newIndex - 1 : newIndex,
                              );
                        },
                        itemBuilder: (context, index) {
                          final material = materialState.materials[index];
                          return Card(
                            key: ValueKey(material.id),
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Icon(
                                material.fileCount > 0 ? Icons.attach_file_rounded : Icons.article_outlined,
                                color: const Color(0xFF2B2B2B),
                              ),
                              title: Text(
                                material.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              subtitle: material.description != null
                                  ? Text(material.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                                  : null,
                              trailing: Text(
                                '${material.fileCount} file(s)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MaterialDetailPage(materialId: material.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}