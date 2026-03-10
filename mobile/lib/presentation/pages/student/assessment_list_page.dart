import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/student/assessment_detail_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_card.dart';
import 'package:likha/presentation/pages/student/widgets/empty_assessment_state.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

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
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId, publishedOnly: true);
    });
  }

  AssessmentStatus _getStatus(Assessment assessment) {
    final now = DateTime.now();
    print('📋 [ListPage] _getStatus() - assessment: ${assessment.title}, submissionCount: ${assessment.submissionCount}, isSubmitted: ${assessment.isSubmitted}, resultsReleased: ${assessment.resultsReleased}, showResultsImmediately: ${assessment.showResultsImmediately}');
    print('📋 [ListPage] _getStatus() - openAt: ${assessment.openAt}, closeAt: ${assessment.closeAt}, now: $now');

    if (assessment.submissionCount > 0) {
      final resultsAccessible =
          assessment.resultsReleased || assessment.showResultsImmediately;
      final isSubmitted = assessment.isSubmitted ?? false;

      print('📋 [ListPage] _getStatus() - has submissions! resultsAccessible: $resultsAccessible, isSubmitted: $isSubmitted');

      // Results are out → show "Submitted" so user knows to go view them
      if (resultsAccessible) {
        print('📋 [ListPage] _getStatus() - returning SUBMITTED (results released)');
        return AssessmentStatus.submitted;
      }

      // Student has submitted, awaiting results → show "Submitted"
      if (isSubmitted) {
        print('📋 [ListPage] _getStatus() - returning SUBMITTED (student submitted)');
        return AssessmentStatus.submitted;
      }

      // Started but not submitted — check if still within window
      final withinWindow =
          now.isAfter(assessment.openAt) && now.isBefore(assessment.closeAt);
      print('📋 [ListPage] _getStatus() - started but not submitted, withinWindow: $withinWindow');
      if (withinWindow) {
        print('📋 [ListPage] _getStatus() - returning IN_PROGRESS (can resume)');
        return AssessmentStatus.inProgress;
      }
      // Past window, not submitted → show "Submitted" (too late)
      print('📋 [ListPage] _getStatus() - returning SUBMITTED (past window, not submitted)');
      return AssessmentStatus.submitted;
    }

    print('📋 [ListPage] _getStatus() - no submissions, checking time window');
    if (now.isBefore(assessment.openAt)) {
      print('📋 [ListPage] _getStatus() - returning NOT_YET_OPEN');
      return AssessmentStatus.notYetOpen;
    }
    if (now.isAfter(assessment.closeAt)) {
      print('📋 [ListPage] _getStatus() - returning CLOSED');
      return AssessmentStatus.closed;
    }
    print('📋 [ListPage] _getStatus() - returning AVAILABLE');
    return AssessmentStatus.available;
  }

  void _onAssessmentTap(Assessment assessment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentDetailPage(assessment: assessment),
      ),
    ).then((_) {
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId, publishedOnly: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    // Listen for sync completion to auto-refresh if data arrives after page opens
    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (!(previous?.assessmentsReady ?? false) && next.assessmentsReady) {
        // Assessments just became ready in the DB — reload
        ref.read(assessmentProvider.notifier).loadAssessments(widget.classId, publishedOnly: true, skipBackgroundRefresh: true);
      }
    });

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
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