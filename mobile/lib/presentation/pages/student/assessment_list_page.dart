import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/student/take_assessment_page.dart';
import 'package:likha/presentation/pages/student/assessment_results_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assessment_state.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class AssessmentListPage extends ConsumerStatefulWidget {
  final String classId;

  const AssessmentListPage({super.key, required this.classId});

  @override
  ConsumerState<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends ConsumerState<AssessmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
    });
  }

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

  void _onAssessmentTap(Assessment assessment) {
    final status = _getStatus(assessment);
    
    if (status == AssessmentStatus.available) {
      // Start assessment directly
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
            .loadAssessments(widget.classId);
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
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEA4335),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: state.isLoading && state.assessments.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2B2B2B),
                  strokeWidth: 2.5,
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(assessmentProvider.notifier)
                    .loadAssessments(widget.classId),
                color: const Color(0xFF2B2B2B),
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: ClassSectionHeader(
                        title: 'Assessments',
                        showBackButton: true,
                      ),
                    ),
                    state.assessments.isEmpty
                        ? const SliverFillRemaining(
                            child: EmptyAssessmentState(),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final assessment = state.assessments[index];
                                  final status = _getStatus(assessment);
                                  return AssessmentCard(
                                    assessment: assessment,
                                    status: status,
                                    onTap: () => _onAssessmentTap(assessment),
                                  );
                                },
                                childCount: state.assessments.length,
                              ),
                            ),
                          ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}