import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/cards/score_display_card.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/student/assessment/assessment_results_page.dart';
import 'package:likha/presentation/pages/student/assessment/take_assessment_page.dart';
import 'package:likha/presentation/widgets/mobile/student/assessment/assessment_action_button.dart';
import 'package:likha/presentation/widgets/mobile/student/assessment/assessment_detail_header.dart';
import 'package:likha/presentation/widgets/mobile/student/assessment/assessment_dialogs.dart';
import 'package:likha/presentation/widgets/mobile/student/assessment/assessment_info_card.dart';
import 'package:likha/presentation/widgets/mobile/student/assessment/assessment_status_banner.dart';
import 'package:likha/presentation/providers/student_assessment_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  final Assessment assessment;

  const AssessmentDetailPage({super.key, required this.assessment});

  @override
  ConsumerState<AssessmentDetailPage> createState() => _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends ConsumerState<AssessmentDetailPage> {
  bool? _submissionIsSubmitted; // Track whether submission is actually submitted
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubmissionStatus();
      final status = _computeDetailStatus();
      if (status == DetailStatus.resultsAvailable) {
        _loadScore();
      }
    });
  }

  DetailStatus _computeDetailStatus() {
    final a = widget.assessment;
    final now = sl<ServerClockService>().now();
    final hasSubmission = _submissionIsSubmitted != null;
    final withinWindow = now.isAfter(a.openAt) && now.isBefore(a.closeAt);
    final resultsAccessible = a.resultsReleased || a.showResultsImmediately;

    PageLogger.instance.log('_computeDetailStatus() - title: ${a.title}, submissionCount: ${a.submissionCount}, withinWindow: $withinWindow, resultsAccessible: $resultsAccessible');

    if (hasSubmission && resultsAccessible) {
      PageLogger.instance.log('_computeDetailStatus() - returning RESULTS_AVAILABLE');
      return DetailStatus.resultsAvailable;
    }
    if (hasSubmission) {
      // Has submission — check if it's actually submitted
      final submissionIsSubmitted = _cachedSubmissionIsSubmitted();
      PageLogger.instance.log('_computeDetailStatus() - hasSubmission: true, submissionIsSubmitted: $submissionIsSubmitted, withinWindow: $withinWindow');

      if (submissionIsSubmitted) {
        // Already submitted → awaiting grading or results
        PageLogger.instance.log('_computeDetailStatus() - returning PENDING_RESULTS (submitted, awaiting grading)');
        return DetailStatus.pendingResults;
      } else if (withinWindow) {
        // Started but not submitted, window still open → resumable
        PageLogger.instance.log('_computeDetailStatus() - returning RESUMABLE (started but not submitted)');
        return DetailStatus.resumable;
      } else {
        // Started but not submitted, window closed → too late
        PageLogger.instance.log('_computeDetailStatus() - returning PENDING_RESULTS (not submitted, window closed)');
        return DetailStatus.pendingResults;
      }
    }
    if (now.isBefore(a.openAt)) {
      PageLogger.instance.log('_computeDetailStatus() - returning NOT_YET_OPEN');
      return DetailStatus.notYetOpen;
    }
    if (now.isAfter(a.closeAt)) {
      PageLogger.instance.log('_computeDetailStatus() - returning CLOSED');
      return DetailStatus.closed;
    }
    PageLogger.instance.log('_computeDetailStatus() - returning AVAILABLE');
    return DetailStatus.available;
  }

  /// Checks if the cached submission is submitted.
  /// Returns false if no submission is cached or if it's not submitted.
  bool _cachedSubmissionIsSubmitted() {
    return _submissionIsSubmitted ?? false;
  }

  Future<void> _loadSubmissionStatus() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      PageLogger.instance.log('_loadSubmissionStatus() - user is null, cannot load submission');
      return;
    }

    try {
      PageLogger.instance.log('_loadSubmissionStatus() START - assessmentId: ${widget.assessment.id}, studentId: ${user.id}');

      // Load the submission to check if it's submitted
      PageLogger.instance.log('_loadSubmissionStatus() - calling loadScorePreview()');
      await ref.read(studentAssessmentProvider.notifier).loadScorePreview(
        widget.assessment.id,
        user.id,
      );

      final assessmentState = ref.read(studentAssessmentProvider);
      // Use the submission's own isSubmitted flag — NOT whether results loaded.
      // Results can 403 (not released yet) even when the submission IS submitted.
      final submission = assessmentState.currentStudentSubmission;
      PageLogger.instance.log('_loadSubmissionStatus() - RESULT: currentStudentSubmission=${submission?.id}, isSubmitted=${submission?.isSubmitted}');

      if (mounted) {
        setState(() {
          _submissionIsSubmitted = submission?.isSubmitted; // null=no sub, false=in-progress, true=submitted
          PageLogger.instance.log('_loadSubmissionStatus() - setState: _submissionIsSubmitted=$_submissionIsSubmitted');
        });
      }
    } catch (e) {
      PageLogger.instance.error('_loadSubmissionStatus() EXCEPTION', e);
    }
  }

  Future<void> _loadScore() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    PageLogger.instance.log('_loadScore() START - assessmentId: ${widget.assessment.id}, studentId: ${user.id}');

    await ref.read(studentAssessmentProvider.notifier).loadScorePreview(
      widget.assessment.id,
      user.id,
    );

    final state = ref.read(studentAssessmentProvider);
    PageLogger.instance.log('_loadScore() END - studentResult: ${state.studentResult}, error: ${state.error}');
  }

  void _navigateToTakeAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TakeAssessmentPage(
          assessmentId: widget.assessment.id,
          timeLimitMinutes: widget.assessment.timeLimitMinutes,
        ),
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _onStartPressed() {
    AssessmentDialogs.showStartConfirmation(
      context,
      timeLimitMinutes: widget.assessment.timeLimitMinutes,
      questionCount: widget.assessment.questionCount,
      onStart: _navigateToTakeAssessment,
    );
  }

  void _onResumePressed() {
    _navigateToTakeAssessment();
  }

  void _onViewResultsPressed() {
    final submissionId = ref.read(studentAssessmentProvider).currentStudentSubmission?.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentResultsPage(
          submissionId: submissionId,
          assessmentId: submissionId == null ? widget.assessment.id : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _computeDetailStatus();
    final state = ref.watch(studentAssessmentProvider);

    ref.listen<StudentAssessmentState>(studentAssessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final isResultsNotReleased =
            next.error!.toLowerCase().contains('not been released');
        if (!isResultsNotReleased) {
          setState(() => _formError = AppErrorMapper.toUserMessage(next.error));
        }
        ref.read(studentAssessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: AssessmentDetailHeader(title: widget.assessment.title),
              ),
            if (_formError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FormMessage(
                    message: _formError,
                    severity: MessageSeverity.error,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                  AssessmentStatusBanner(
                    status: status,
                    openAt: widget.assessment.openAt,
                    closeAt: widget.assessment.closeAt,
                  ),
                  AssessmentInfoCard(
                    description: widget.assessment.description,
                    totalPoints: widget.assessment.totalPoints,
                    timeLimitMinutes: widget.assessment.timeLimitMinutes,
                    questionCount: widget.assessment.questionCount,
                    openAt: widget.assessment.openAt,
                    closeAt: widget.assessment.closeAt,
                  ),
                  if (status == DetailStatus.resultsAvailable) ...[
                    ScoreDisplayCard(
                      score: state.studentResult?.finalScore ?? 0,
                      totalPoints: widget.assessment.totalPoints,
                      isLoading: state.isLoading,
                      useBaseCardStyle: false,
                    ),
                    AssessmentActionButton(
                      variant: AssessmentActionVariant.viewResults,
                      onPressed: _onViewResultsPressed,
                    ),
                  ] else if (status == DetailStatus.available) ...[
                    AssessmentActionButton(
                      variant: AssessmentActionVariant.start,
                      onPressed: _onStartPressed,
                    ),
                  ] else if (status == DetailStatus.resumable) ...[
                    AssessmentActionButton(
                      variant: AssessmentActionVariant.resume,
                      onPressed: _onResumePressed,
                    ),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
