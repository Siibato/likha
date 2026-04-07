import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/assessment.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/edit_assessment_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment_submissions_desktop.dart';
import 'package:likha/presentation/pages/desktop/teacher/assessment_statistics_desktop.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';
import 'package:likha/presentation/utils/formatters.dart';

class AssessmentDetailDesktop extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentDetailDesktop({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentDetailDesktop> createState() =>
      _AssessmentDetailDesktopState();
}

class _AssessmentDetailDesktopState
    extends ConsumerState<AssessmentDetailDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadAssessmentDetail(widget.assessmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);
    final assessment = state.currentAssessment;
    final questions = state.questions;

    ref.listen<TeacherAssessmentState>(teacherAssessmentProvider,
        (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
        ref.read(teacherAssessmentProvider.notifier).clearMessages();

        if (next.successMessage == 'Assessment deleted') {
          Navigator.of(context).pop();
          return;
        }

        // Reload on question/assessment changes
        if (next.successMessage == 'Questions added' ||
            next.successMessage == 'Question updated' ||
            next.successMessage == 'Question deleted' ||
            next.successMessage == 'Assessment updated' ||
            next.successMessage == 'Assessment published' ||
            next.successMessage == 'Assessment moved to draft' ||
            next.successMessage == 'Results released') {
          ref
              .read(teacherAssessmentProvider.notifier)
              .loadAssessmentDetail(widget.assessmentId);
        }
      }

      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.semanticError,
          ),
        );
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: assessment?.title ?? 'Assessment Detail',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (assessment != null) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditAssessmentDesktop(
                      assessment: assessment!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foregroundDark,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.foregroundDark),
              onSelected: (value) => _handleMenuAction(value, assessment),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: assessment.isPublished ? 'unpublish' : 'publish',
                  child: Row(
                    children: [
                      Icon(
                        assessment.isPublished
                            ? Icons.unpublished_rounded
                            : Icons.publish_rounded,
                        size: 18,
                        color: AppColors.foregroundSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(assessment.isPublished ? 'Unpublish' : 'Publish'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'release_results',
                  enabled: !assessment.resultsReleased,
                  child: Row(
                    children: [
                      Icon(
                        Icons.grading_rounded,
                        size: 18,
                        color: assessment.resultsReleased
                            ? AppColors.foregroundTertiary
                            : AppColors.foregroundSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Release Results',
                        style: TextStyle(
                          color: assessment.resultsReleased
                              ? AppColors.foregroundTertiary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded,
                          size: 18, color: AppColors.semanticError),
                      SizedBox(width: 12),
                      Text('Delete',
                          style: TextStyle(color: AppColors.semanticError)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        body: state.isLoading && assessment == null
            ? const Center(child: CircularProgressIndicator())
            : assessment == null
                ? const Center(
                    child: Text(
                      'Assessment not found',
                      style: TextStyle(color: AppColors.foregroundTertiary),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBadge(assessment),
                            const SizedBox(height: 24),
                            _buildInfoSection(assessment),
                            const SizedBox(height: 24),
                            _buildQuestionsSection(questions),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right column
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildQuickStats(assessment, questions),
                            const SizedBox(height: 16),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatusBadge(Assessment assessment) {
    final isPublished = assessment.isPublished;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.semanticSuccessBackground
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? AppColors.semanticSuccess
              : AppColors.deprecatedDraftOrange,
        ),
      ),
    );
  }

  Widget _buildInfoSection(Assessment assessment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          if (assessment.description != null &&
              assessment.description!.isNotEmpty) ...[
            Text(
              assessment.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.foregroundSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(
            Icons.timer_rounded,
            'Time Limit',
            assessment.timeLimitMinutes > 0
                ? '${assessment.timeLimitMinutes} minutes'
                : 'No limit',
          ),
          _buildInfoRow(
            Icons.stars_rounded,
            'Total Points',
            '${assessment.totalPoints}',
          ),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Open Date',
            formatDateTimeDisplay(assessment.openAt),
          ),
          _buildInfoRow(
            Icons.event_rounded,
            'Close Date',
            formatDateTimeDisplay(assessment.closeAt),
          ),
          _buildInfoRow(
            Icons.people_rounded,
            'Submissions',
            '${assessment.submissionCount}',
          ),
          _buildInfoRow(
            Icons.grading_rounded,
            'Results Released',
            assessment.resultsReleased ? 'Yes' : 'No',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.foregroundTertiary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(List<Question> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${questions.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                'No questions added yet',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildQuestionCard(questions[index], index + 1),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, int number) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeBadge(question.questionType),
                    const SizedBox(width: 8),
                    Text(
                      '${question.points} pt${question.points != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        Formatters.questionTypeLabel(type),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.foregroundSecondary,
        ),
      ),
    );
  }

  Widget _buildQuickStats(Assessment assessment, List<Question> questions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Submissions', '${assessment.submissionCount}'),
          const SizedBox(height: 12),
          _buildStatRow('Questions', '${questions.length}'),
          const SizedBox(height: 12),
          _buildStatRow('Total Points', '${assessment.totalPoints}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foregroundDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AssessmentSubmissionsDesktop(
                    assessmentId: widget.assessmentId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: const Text('View Submissions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foregroundDark,
              side: const BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AssessmentStatisticsDesktop(
                    assessmentId: widget.assessmentId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: const Text('View Statistics'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foregroundDark,
              side: const BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Assessment assessment) {
    switch (action) {
      case 'publish':
        AppDialogs.showConfirmation(
          context: context,
          title: 'Publish Assessment',
          body:
              'This will make the assessment visible to students. Are you sure?',
          confirmLabel: 'Publish',
          onConfirm: () => ref
              .read(teacherAssessmentProvider.notifier)
              .publishAssessment(widget.assessmentId),
        );
        break;
      case 'unpublish':
        AppDialogs.showDestructive(
          context: context,
          title: 'Unpublish Assessment',
          body:
              'This will hide the assessment from students. Existing submissions will be kept.',
          confirmLabel: 'Unpublish',
          onConfirm: () => ref
              .read(teacherAssessmentProvider.notifier)
              .unpublishAssessment(widget.assessmentId),
        );
        break;
      case 'release_results':
        AppDialogs.showConfirmation(
          context: context,
          title: 'Release Results',
          body:
              'Students will be able to see their scores and answers. This cannot be undone.',
          confirmLabel: 'Release',
          onConfirm: () => ref
              .read(teacherAssessmentProvider.notifier)
              .releaseResults(widget.assessmentId),
        );
        break;
      case 'delete':
        AppDialogs.showDestructive(
          context: context,
          title: 'Delete Assessment',
          body:
              'This will permanently delete the assessment and all its questions. This cannot be undone.',
          confirmLabel: 'Delete',
          onConfirm: () => ref
              .read(teacherAssessmentProvider.notifier)
              .deleteAssessment(widget.assessmentId),
        );
        break;
    }
  }
}
