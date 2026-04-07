import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/domain/assessments/usecases/override_answer.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/status_badge.dart';
import 'package:likha/presentation/pages/shared/widgets/dialogs/app_dialogs.dart';
import 'package:likha/presentation/providers/teacher_assessment_provider.dart';

class SubmissionReviewDesktop extends ConsumerStatefulWidget {
  final String submissionId;

  const SubmissionReviewDesktop({super.key, required this.submissionId});

  @override
  ConsumerState<SubmissionReviewDesktop> createState() =>
      _SubmissionReviewDesktopState();
}

class _SubmissionReviewDesktopState
    extends ConsumerState<SubmissionReviewDesktop> {
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(teacherAssessmentProvider.notifier)
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
      case 'essay':
        return 'Essay';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
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
    await ref.read(teacherAssessmentProvider.notifier).overrideAnswer(
          OverrideAnswerParams(
            answerId: answerId,
            isCorrect: isCorrect,
          ),
        );

    if (!mounted) return;
    final state = ref.read(teacherAssessmentProvider);
    if (state.error == null) {
      ref
          .read(teacherAssessmentProvider.notifier)
          .loadSubmissionDetail(widget.submissionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherAssessmentProvider);
    final detail = state.currentSubmission;

    ref.listen<TeacherAssessmentState>(teacherAssessmentProvider,
        (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        setState(() => _formError = null);
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        setState(
            () => _formError = AppErrorMapper.toUserMessage(next.error));
        ref.read(teacherAssessmentProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: detail != null ? detail.studentName : 'Submission Review',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.foregroundPrimary),
          onPressed: () => Navigator.pop(context),
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
                      style:
                          TextStyle(color: AppColors.foregroundTertiary),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormMessage(
                        message: _formError,
                        severity: MessageSeverity.error,
                      ),
                      if (_formError != null) const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left panel - Answers list
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.only(right: 24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Answers',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.foregroundDark,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...detail.answers
                                        .asMap()
                                        .entries
                                        .map((entry) =>
                                            _buildAnswerCard(
                                                entry.value,
                                                entry.key)),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),

                            // Right panel - Grading panel
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                child: _buildGradingPanel(detail),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildGradingPanel(SubmissionDetail detail) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundTertiary,
                radius: 20,
                child: Text(
                  detail.studentName.isNotEmpty
                      ? detail.studentName[0].toUpperCase()
                      : '?',
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
                    Text(
                      detail.studentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StatusBadge(
                      label: detail.isSubmitted
                          ? 'Submitted'
                          : 'In Progress',
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
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),

          // Score summary
          _scoreRow('Auto Score', detail.autoScore,
              AppColors.foregroundSecondary),
          const SizedBox(height: 12),
          _scoreRow('Final Score', detail.finalScore,
              AppColors.foregroundPrimary),
          const SizedBox(height: 12),
          _scoreRow('Total Points', detail.totalPoints.toDouble(),
              AppColors.foregroundTertiary),

          if (detail.submittedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Text(
              'Submitted: ${_formatDateTime(detail.submittedAt!)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),

          // Per-question override section
          const Text(
            'Grade Overrides',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...detail.answers.asMap().entries.map((entry) {
            final answer = entry.value;
            final index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.borderLight, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}. ${answer.questionText}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foregroundPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _confirmOverride(answer, true),
                              icon: const Icon(Icons.check,
                                  size: 16),
                              label: const Text('Correct',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AppColors.semanticSuccess,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _confirmOverride(answer, false),
                              icon: const Icon(Icons.close,
                                  size: 16),
                              label: const Text('Incorrect',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AppColors.semanticError,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double value, Color color) {
    final display =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.foregroundTertiary,
          ),
        ),
        Text(
          display,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerCard(SubmissionAnswer answer, int index) {
    final isAutoCorrect = answer.isAutoCorrect ??
        (answer.pointsAwarded >= answer.points && answer.points > 0);
    final isOverrideCorrect = answer.isOverrideCorrect;
    final effectiveCorrect = isOverrideCorrect ?? isAutoCorrect;
    final isPartial =
        answer.pointsAwarded > 0 && answer.pointsAwarded < answer.points;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}. ${answer.questionText}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.foregroundDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge(
                          label: _questionTypeLabel(answer.questionType),
                          color: AppColors.foregroundSecondary,
                          variant: BadgeVariant.outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${answer.points} pt${answer.points != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                label:
                    '${answer.pointsAwarded % 1 == 0 ? answer.pointsAwarded.toInt() : answer.pointsAwarded.toStringAsFixed(1)} / ${answer.points}',
                color: statusColor,
                variant: BadgeVariant.filled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Answer content
          _buildAnswerContent(answer),

          if (isOverrideCorrect != null) ...[
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Grade overridden',
              color: AppColors.deprecatedWarningYellow,
              icon: Icons.edit_outlined,
              variant: BadgeVariant.filled,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerContent(SubmissionAnswer answer) {
    switch (answer.questionType) {
      case 'multiple_choice':
        return _buildMCContent(answer);
      case 'identification':
      case 'essay':
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
      return const Text('No answer',
          style: TextStyle(color: AppColors.foregroundTertiary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: choices
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      c.isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: c.isCorrect
                          ? AppColors.semanticSuccess
                          : AppColors.semanticError,
                    ),
                    const SizedBox(width: 8),
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
      return const Text('No answers',
          style: TextStyle(color: AppColors.foregroundTertiary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: enumAnswers.asMap().entries.map((entry) {
        final idx = entry.key;
        final ea = entry.value;
        final isCorrect =
            ea.isOverrideCorrect ?? ea.isAutoCorrect ?? ea.isCorrect;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${idx + 1}.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ),
              Icon(
                isCorrect ? Icons.check : Icons.close,
                size: 16,
                color: isCorrect
                    ? AppColors.semanticSuccess
                    : AppColors.semanticError,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ea.answerText.isNotEmpty ? ea.answerText : '(blank)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
