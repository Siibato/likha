import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/student/take_assessment_page.dart';
import 'package:likha/presentation/pages/student/assessment_results_page.dart';
import 'package:likha/presentation/pages/student/assignment_detail_page.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_card.dart';
import 'package:likha/presentation/pages/student/widgets/assignment_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assessment_state.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assignment_state.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/learning_material_provider.dart';
import 'package:likha/presentation/pages/teacher/material_detail_page.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';

class StudentClassDetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String classTitle;

  const StudentClassDetailPage({
    super.key,
    required this.classId,
    required this.classTitle,
  });

  @override
  ConsumerState<StudentClassDetailPage> createState() =>
      _StudentClassDetailPageState();
}

class _StudentClassDetailPageState extends ConsumerState<StudentClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.classTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssessmentTab(classId: widget.classId),
          _AssignmentTab(classId: widget.classId),
          _ModulesTab(classId: widget.classId),
        ],
      ),
    );
  }
}

class _AssessmentTab extends ConsumerWidget {
  final String classId;

  const _AssessmentTab({required this.classId});

  AssessmentStatus _getStatus(Assessment assessment) {
    final now = DateTime.now();
    if (assessment.submissionCount > 0) {
      return AssessmentStatus.submitted;
    }
    if (now.isBefore(assessment.openAt)) {
      return AssessmentStatus.notYetOpen;
    }
    if (now.isAfter(assessment.closeAt)) {
      return AssessmentStatus.closed;
    }
    return AssessmentStatus.available;
  }

  void _onAssessmentTap(BuildContext context, WidgetRef ref, Assessment assessment) {
    final status = _getStatus(assessment);
    
    if (status == AssessmentStatus.available) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TakeAssessmentPage(
            assessmentId: assessment.id,
            timeLimitMinutes: assessment.timeLimitMinutes,
          ),
        ),
      ).then((_) {
        ref
            .read(assessmentProvider.notifier)
            .loadAssessments(classId);
      });
    } else if (status == AssessmentStatus.submitted &&
        (assessment.resultsReleased || assessment.showResultsImmediately)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentResultsPage(assessmentId: assessment.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assessmentProvider);

    return state.isLoading && state.assessments.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B2B2B),
              strokeWidth: 2.5,
            ),
          )
        : state.assessments.isEmpty
            ? const EmptyAssessmentState()
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assessmentProvider.notifier)
                    .loadAssessments(classId),
                color: const Color(0xFF2B2B2B),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = state.assessments[index];
                    final status = _getStatus(assessment);
                    return AssessmentCard(
                      assessment: assessment,
                      status: status,
                      onTap: () => _onAssessmentTap(context, ref, assessment),
                    );
                  },
                ),
              );
  }
}

class _AssignmentTab extends ConsumerWidget {
  final String classId;

  const _AssignmentTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);

    return state.isLoading && state.assignments.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B2B2B),
              strokeWidth: 2.5,
            ),
          )
        : state.assignments.isEmpty
            ? const EmptyAssignmentState()
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assignmentProvider.notifier)
                    .loadAssignments(classId),
                color: const Color(0xFF2B2B2B),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = state.assignments[index];
                    final isPastDue =
                        DateTime.now().isAfter(assignment.dueAt);

                    return AssignmentCard(
                      title: assignment.title,
                      totalPoints: assignment.totalPoints,
                      dueAt: assignment.dueAt,
                      isPastDue: isPastDue,
                      submissionStatus: assignment.submissionStatus,
                      score: assignment.score,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentDetailPage(
                            assignmentId: assignment.id,
                            assignmentTitle: assignment.title,
                            instructions: assignment.instructions,
                            submissionType: assignment.submissionType,
                            totalPoints: assignment.totalPoints,
                            allowedFileTypes: assignment.allowedFileTypes,
                            maxFileSizeMb: assignment.maxFileSizeMb,
                            submissionId: assignment.submissionId,
                            score: assignment.score,
                            submissionStatus: assignment.submissionStatus,
                          ),
                        ),
                      ).then((_) => ref
                          .read(assignmentProvider.notifier)
                          .loadAssignments(classId)),
                    );
                  },
                ),
              );
  }
}

class _ModulesTab extends ConsumerWidget {
  final String classId;

  const _ModulesTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningMaterialProvider);

    return state.isLoading && state.materials.isEmpty
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B2B2B),
              strokeWidth: 2.5,
            ),
          )
        : state.materials.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 64,
                      color: Color(0xFFCCCCCC),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No modules yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(learningMaterialProvider.notifier)
                    .loadMaterials(classId),
                color: const Color(0xFF2B2B2B),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.materials.length,
                  itemBuilder: (context, index) {
                    final material = state.materials[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          material.fileCount > 0
                              ? Icons.attach_file_rounded
                              : Icons.article_outlined,
                          color: const Color(0xFF2B2B2B),
                        ),
                        title: Text(
                          material.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: material.description != null
                            ? Text(
                                material.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Text(
                          '${material.fileCount} file(s)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaterialDetailPage(
                              materialId: material.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}