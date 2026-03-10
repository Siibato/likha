import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/snackbar_utils.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/status_badge.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';

class SubmissionReviewPage extends ConsumerStatefulWidget {
  final String submissionId;

  const SubmissionReviewPage({super.key, required this.submissionId});

  @override
  ConsumerState<SubmissionReviewPage> createState() =>
      _SubmissionReviewPageState();
}

class _SubmissionReviewPageState extends ConsumerState<SubmissionReviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assessmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    });
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'identification':
        return 'Identification';
      case 'enumeration':
        return 'Enumeration';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/${dt.year} $hour:$minute $period';
  }

  void _confirmOverride(SubmissionAnswer answer, bool isCorrect) {
    final action = isCorrect ? 'correct' : 'incorrect';
    AppDialogs.showConfirmation(
      context: context,
      title: 'Override Grade',
      body: 'Mark this answer as $action?',
      confirmLabel: 'Confirm',
      onConfirm: () => _overrideAnswer(answer.id, isCorrect),
    );
  }

  Future<void> _overrideAnswer(String answerId, bool isCorrect) async {
    await ref.read(assessmentProvider.notifier).overrideAnswer(
          OverrideAnswerParams(
            answerId: answerId,
            isCorrect: isCorrect,
          ),
        );

    if (!mounted) return;
    final state = ref.read(assessmentProvider);
    if (state.error == null) {
      // Reload submission detail to reflect updated scores
      ref
          .read(assessmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final detail = state.currentSubmission;

    ref.listen<AssessmentState>(assessmentProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        context.showErrorSnackBar(next.error!);
        ref.read(assessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foregroundPrimary),
        title: Text(
          detail != null ? detail.studentName : 'Submission Review',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: state.isLoading && detail == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : detail == null
              ? const Center(
                  child: Text(
                    'Submission not found',
                    style: TextStyle(color: AppColors.foregroundTertiary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryCard(detail),
                      const SizedBox(height: 16),
                      Text(
                        'Answers',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foregroundDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...detail.answers.asMap().entries.map(
                            (entry) => _buildAnswerCard(entry.value, entry.key),
                          ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(SubmissionDetail detail) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundTertiary,
                child: Text(
                  detail.studentName.isNotEmpty ? detail.studentName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.foregroundPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.studentName, style: AppTextStyles.cardTitleMd),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: detail.isSubmitted ? 'Submitted' : 'In Progress',
                      color: detail.isSubmitted
                          ? AppColors.semanticSuccess
                          : AppColors.foregroundSecondary,
                      variant: BadgeVariant.filled,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreColumn('Auto Score', detail.autoScore, AppColors.foregroundSecondary),
              _scoreColumn('Final Score', detail.finalScore, AppColors.foregroundPrimary),
            ],
          ),
          if (detail.submittedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Submitted: ${_formatDateTime(detail.submittedAt!)}',
              style: AppTextStyles.cardSubtitleMd,
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, double score, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.foregroundTertiary)),
        const SizedBox(height: 4),
        Text(
          score % 1 == 0 ? score.toInt().toString() : score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerCard(SubmissionAnswer answer, int index) {
    final isAutoCorrect = answer.isAutoCorrect == true;
    final isOverrideCorrect = answer.isOverrideCorrect;
    final effectiveCorrect = isOverrideCorrect ?? isAutoCorrect;
    final isPartial = answer.pointsAwarded > 0 && answer.pointsAwarded < answer.points;

    Color statusColor;
    IconData statusIcon;
    if (effectiveCorrect) {
      statusColor = AppColors.semanticSuccess;
      statusIcon = Icons.check_circle;
    } else if (isPartial) {
      statusColor = AppColors.foregroundSecondary;
      statusIcon = Icons.remove_circle;
    } else {
      statusColor = AppColors.semanticError;
      statusIcon = Icons.cancel;
    }

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}. ${answer.questionText}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.foregroundDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_questionTypeLabel(answer.questionType)} - ${answer.points} pt${answer.points != 1 ? 's' : ''}',
                      style: AppTextStyles.cardSubtitleSm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: '${answer.pointsAwarded % 1 == 0 ? answer.pointsAwarded.toInt() : answer.pointsAwarded.toStringAsFixed(1)} / ${answer.points}',
                color: statusColor,
                variant: BadgeVariant.filled,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          _buildAnswerContent(answer),
          if (isOverrideCorrect != null) ...[
            const SizedBox(height: 8),
            StatusBadge(
              label: 'Grade overridden',
              color: AppColors.deprecatedWarningYellow,
              icon: Icons.edit_outlined,
              variant: BadgeVariant.filled,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _confirmOverride(answer, true),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Mark Correct'),
                style: TextButton.styleFrom(foregroundColor: AppColors.semanticSuccess),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmOverride(answer, false),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Mark Incorrect'),
                style: TextButton.styleFrom(foregroundColor: AppColors.semanticError),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerContent(SubmissionAnswer answer) {
    switch (answer.questionType) {
      case 'multiple_choice':
        return _buildMCContent(answer);
      case 'identification':
        return _buildIdentificationContent(answer);
      case 'enumeration':
        return _buildEnumerationContent(answer);
      default:
        return const Text('Unknown question type');
    }
  }

  Widget _buildMCContent(SubmissionAnswer answer) {
    final choices = answer.selectedChoices ?? [];
    if (choices.isEmpty) {
      return const Text('No answer', style: TextStyle(color: AppColors.foregroundTertiary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: choices
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      c.isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: c.isCorrect ? AppColors.semanticSuccess : AppColors.semanticError,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.choiceText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildIdentificationContent(SubmissionAnswer answer) {
    return Text(
      answer.answerText?.isNotEmpty == true
          ? 'Answer: ${answer.answerText}'
          : 'No answer',
      style: TextStyle(
        fontSize: 14,
        color: answer.answerText?.isNotEmpty == true
            ? AppColors.foregroundPrimary
            : AppColors.foregroundTertiary,
      ),
    );
  }

  Widget _buildEnumerationContent(SubmissionAnswer answer) {
    final enumAnswers = answer.enumerationAnswers ?? [];
    if (enumAnswers.isEmpty) {
      return const Text('No answers', style: TextStyle(color: AppColors.foregroundTertiary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: enumAnswers.asMap().entries.map((entry) {
        final idx = entry.key;
        final ea = entry.value;
        final isCorrect = ea.isAutoCorrect == true || ea.isOverrideCorrect == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('${idx + 1}.',
                    style: const TextStyle(fontSize: 13, color: AppColors.foregroundTertiary)),
              ),
              Icon(
                isCorrect ? Icons.check : Icons.close,
                size: 16,
                color: isCorrect ? AppColors.semanticSuccess : AppColors.semanticError,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ea.answerText.isNotEmpty ? ea.answerText : '(blank)',
                  style: const TextStyle(fontSize: 14, color: AppColors.foregroundPrimary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
