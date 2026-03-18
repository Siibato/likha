import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/student/assessment_detail_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
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
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId, publishedOnly: true);
    });
  }

  AssessmentStatus _getStatus(Assessment assessment) {
    final now = sl<ServerClockService>().now();
    debugPrint('📋 [ListPage] _getStatus() - assessment: ${assessment.title}, submissionCount: ${assessment.submissionCount}, isSubmitted: ${assessment.isSubmitted}, resultsReleased: ${assessment.resultsReleased}, showResultsImmediately: ${assessment.showResultsImmediately}');
    debugPrint('📋 [ListPage] _getStatus() - openAt: ${assessment.openAt}, closeAt: ${assessment.closeAt}, now: $now');

    if (assessment.isSubmitted != null) {
      final resultsAccessible =
          assessment.resultsReleased || assessment.showResultsImmediately;
      final isSubmitted = assessment.isSubmitted ?? false;

      debugPrint('📋 [ListPage] _getStatus() - has submissions! resultsAccessible: $resultsAccessible, isSubmitted: $isSubmitted');

      // Results are out → show "Submitted" so user knows to go view them
      if (resultsAccessible) {
        debugPrint('📋 [ListPage] _getStatus() - returning SUBMITTED (results released)');
        return AssessmentStatus.submitted;
      }

      // Student has submitted, awaiting results → show "Submitted"
      if (isSubmitted) {
        debugPrint('📋 [ListPage] _getStatus() - returning SUBMITTED (student submitted)');
        return AssessmentStatus.submitted;
      }

      // Started but not submitted — check if still within window
      final withinWindow =
          now.isAfter(assessment.openAt) && now.isBefore(assessment.closeAt);
      debugPrint('📋 [ListPage] _getStatus() - started but not submitted, withinWindow: $withinWindow');
      if (withinWindow) {
        debugPrint('📋 [ListPage] _getStatus() - returning IN_PROGRESS (can resume)');
        return AssessmentStatus.inProgress;
      }
      // Past window, not submitted → show "Submitted" (too late)
      debugPrint('📋 [ListPage] _getStatus() - returning SUBMITTED (past window, not submitted)');
      return AssessmentStatus.submitted;
    }

    debugPrint('📋 [ListPage] _getStatus() - no submissions, checking time window');
    if (now.isBefore(assessment.openAt)) {
      debugPrint('📋 [ListPage] _getStatus() - returning NOT_YET_OPEN');
      return AssessmentStatus.notYetOpen;
    }
    if (now.isAfter(assessment.closeAt)) {
      debugPrint('📋 [ListPage] _getStatus() - returning CLOSED');
      return AssessmentStatus.closed;
    }
    debugPrint('📋 [ListPage] _getStatus() - returning AVAILABLE');
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
        final isResultsNotReleased =
            next.error!.toLowerCase().contains('not been released');
        if (!isResultsNotReleased) {
          setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        }
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
                    .loadAssessments(widget.classId, publishedOnly: true),
                color: const Color(0xFF2B2B2B),
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: ClassSectionHeader(
                        title: 'Assessments',
                        showBackButton: true,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FormMessage(
                          message: _formError,
                          severity: MessageSeverity.error,
                        ),
                      ),
                    ),
                    if (_formError != null) const SliverToBoxAdapter(child: SizedBox(height: 12)),
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