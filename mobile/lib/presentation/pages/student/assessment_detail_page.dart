import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/services/server_clock_service.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/presentation/pages/student/assessment_results_page.dart';
import 'package:likha/presentation/pages/student/take_assessment_page.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_dialogs.dart';
import 'package:likha/presentation/pages/student/widgets/assessment_status_banner.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class AssessmentDetailPage extends ConsumerStatefulWidget {
  final Assessment assessment;

  const AssessmentDetailPage({super.key, required this.assessment});

  @override
  ConsumerState<AssessmentDetailPage> createState() => _AssessmentDetailPageState();
}

class _AssessmentDetailPageState extends ConsumerState<AssessmentDetailPage> {
  bool _isLoadingScore = false;
  bool? _submissionIsSubmitted; // Track whether submission is actually submitted

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

    print('📄 [DetailPage] _computeDetailStatus() - title: ${a.title}, submissionCount: ${a.submissionCount}, withinWindow: $withinWindow, resultsAccessible: $resultsAccessible');

    if (hasSubmission && resultsAccessible) {
      print('📄 [DetailPage] _computeDetailStatus() - returning RESULTS_AVAILABLE');
      return DetailStatus.resultsAvailable;
    }
    if (hasSubmission) {
      // Has submission — check if it's actually submitted
      final submissionIsSubmitted = _cachedSubmissionIsSubmitted();
      print('📄 [DetailPage] _computeDetailStatus() - hasSubmission: true, submissionIsSubmitted: $submissionIsSubmitted, withinWindow: $withinWindow');

      if (submissionIsSubmitted) {
        // Already submitted → awaiting grading or results
        print('📄 [DetailPage] _computeDetailStatus() - returning PENDING_RESULTS (submitted, awaiting grading)');
        return DetailStatus.pendingResults;
      } else if (withinWindow) {
        // Started but not submitted, window still open → resumable
        print('📄 [DetailPage] _computeDetailStatus() - returning RESUMABLE (started but not submitted)');
        return DetailStatus.resumable;
      } else {
        // Started but not submitted, window closed → too late
        print('📄 [DetailPage] _computeDetailStatus() - returning PENDING_RESULTS (not submitted, window closed)');
        return DetailStatus.pendingResults;
      }
    }
    if (now.isBefore(a.openAt)) {
      print('📄 [DetailPage] _computeDetailStatus() - returning NOT_YET_OPEN');
      return DetailStatus.notYetOpen;
    }
    if (now.isAfter(a.closeAt)) {
      print('📄 [DetailPage] _computeDetailStatus() - returning CLOSED');
      return DetailStatus.closed;
    }
    print('📄 [DetailPage] _computeDetailStatus() - returning AVAILABLE');
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
      print('❌ [DetailPage] _loadSubmissionStatus() - user is null, cannot load submission');
      return;
    }

    try {
      print('🔍 [DetailPage] _loadSubmissionStatus() START - assessmentId: ${widget.assessment.id}, studentId: ${user.id}');

      // Load the submission to check if it's submitted
      print('🔍 [DetailPage] _loadSubmissionStatus() - calling loadScorePreview()');
      await ref.read(assessmentProvider.notifier).loadScorePreview(
        widget.assessment.id,
        user.id,
      );

      final assessmentState = ref.read(assessmentProvider);
      // Use the submission's own isSubmitted flag — NOT whether results loaded.
      // Results can 403 (not released yet) even when the submission IS submitted.
      final isSubmitted = assessmentState.currentStudentSubmission?.isSubmitted ?? false;
      print('🔍 [DetailPage] _loadSubmissionStatus() - RESULT: currentStudentSubmission=${assessmentState.currentStudentSubmission?.id}, isSubmitted=$isSubmitted');

      if (mounted) {
        setState(() {
          _submissionIsSubmitted = isSubmitted;
          print('🔍 [DetailPage] _loadSubmissionStatus() - setState: _submissionIsSubmitted=$_submissionIsSubmitted');
        });
      }
    } catch (e, st) {
      print('❌ [DetailPage] _loadSubmissionStatus() EXCEPTION: $e');
      print('❌ [DetailPage] _loadSubmissionStatus() STACK: $st');
    }
  }

  Future<void> _loadScore() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    print('🔍 [DetailPage] _loadScore() START - assessmentId: ${widget.assessment.id}, studentId: ${user.id}');
    setState(() => _isLoadingScore = true);

    await ref.read(assessmentProvider.notifier).loadScorePreview(
      widget.assessment.id,
      user.id,
    );

    final state = ref.read(assessmentProvider);
    print('🔍 [DetailPage] _loadScore() END - studentResult: ${state.studentResult}, error: ${state.error}');
    if (mounted) setState(() => _isLoadingScore = false);
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
    final submissionId = ref.read(assessmentProvider).currentStudentSubmission?.id;
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
    final state = ref.watch(assessmentProvider);

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AssessmentStatusBanner(
                    status: status,
                    openAt: widget.assessment.openAt,
                    closeAt: widget.assessment.closeAt,
                  ),
                  _buildInfoCard(),
                  if (status == DetailStatus.resultsAvailable) ...[
                    _buildScorePreviewCard(state),
                    _buildViewResultsButton(),
                  ] else if (status == DetailStatus.available) ...[
                    _buildStartButton(),
                  ] else if (status == DetailStatus.resumable) ...[
                    _buildResumeButton(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 32, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 3),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.assessment.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.assessment.description != null && widget.assessment.description!.isNotEmpty) ...[
              Text(
                widget.assessment.description!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2B2B2B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _InfoChip(
                  icon: Icons.star_outline_rounded,
                  label: '${widget.assessment.totalPoints} pts',
                ),
                const SizedBox(width: 14),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: _formatTimeLimit(widget.assessment.timeLimitMinutes),
                ),
                const SizedBox(width: 14),
                _InfoChip(
                  icon: Icons.help_outline_rounded,
                  label:
                      '${widget.assessment.questionCount} question${widget.assessment.questionCount != 1 ? 's' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DateRow(
              icon: Icons.calendar_today_rounded,
              label: 'Opens',
              dateTime: _formatDateTime(widget.assessment.openAt),
            ),
            const SizedBox(height: 6),
            _DateRow(
              icon: Icons.event_rounded,
              label: 'Closes',
              dateTime: _formatDateTime(widget.assessment.closeAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePreviewCard(AssessmentState state) {
    if (_isLoadingScore) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B2B2B),
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    final result = state.studentResult;
    if (result == null) {
      return const SizedBox.shrink();
    }

    final totalPoints = result.totalPoints.toDouble();
    final finalScore = result.finalScore;
    final percentage = totalPoints > 0 ? (finalScore / totalPoints) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  finalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                Text(
                  ' / $totalPoints',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 10,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2B2B2B)),
                value: totalPoints > 0 ? finalScore / totalPoints : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _onStartPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF34A853),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_arrow_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Assessment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _onResumePressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFBD59),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_circle_rounded, size: 20, color: Color(0xFF2B2B2B)),
            SizedBox(width: 8),
            Text(
              'Resume Assessment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B2B2B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewResultsButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _onViewResultsPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2B2B2B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bar_chart_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'View Full Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeLimit(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (remaining == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      }
      return '$hours hr${hours > 1 ? 's' : ''} $remaining min';
    }
    return '$minutes min';
  }

  String _formatDateTime(DateTime dt) {
    // Convert UTC to device local time before formatting
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF666666)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String dateTime;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF999999)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          dateTime,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
