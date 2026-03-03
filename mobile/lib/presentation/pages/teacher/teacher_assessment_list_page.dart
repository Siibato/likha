import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/teacher/assessment_detail_page.dart';
import 'package:likha/presentation/pages/teacher/create_assessment_page.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_assessment_list_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/teacher_assessment_card.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class TeacherAssessmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const TeacherAssessmentListPage({super.key, required this.classId});

  @override
  ConsumerState<TeacherAssessmentListPage> createState() =>
      _TeacherAssessmentListPageState();
}

class _TeacherAssessmentListPageState extends ConsumerState<TeacherAssessmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            ClassSectionHeader(
              title: 'Assessments',
              showBackButton: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateAssessmentPage(classId: widget.classId),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
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
              child: assessmentState.isLoading && assessmentState.assessments.isEmpty
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
                              final assessment = assessmentState.assessments[index];
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
        ),
      ),
    );
  }
}
