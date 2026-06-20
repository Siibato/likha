import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/utils/labels.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';

/// Individual answer card for the desktop submission review page.
class SubmissionReviewAnswerCard extends StatelessWidget {
  final SubmissionAnswer answer;
  final int index;
  final VoidCallback onOverride;

  const SubmissionReviewAnswerCard({
    super.key,
    required this.answer,
    required this.index,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
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
                          label: questionTypeLabel(answer.questionType),
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
          _AnswerContent(answer: answer),

          if (isOverrideCorrect != null) ...[
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Grade overridden',
              color: AppColors.accentAmber,
              icon: Icons.edit_outlined,
              variant: BadgeVariant.filled,
            ),
          ],

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOverride,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Override'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foregroundPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  final SubmissionAnswer answer;

  const _AnswerContent({required this.answer});

  @override
  Widget build(BuildContext context) {
    switch (answer.questionType) {
      case 'multiple_choice':
        return _MCContent(answer: answer);
      case 'identification':
      case 'essay':
        return _IdentificationContent(answer: answer);
      case 'enumeration':
        return _EnumerationContent(answer: answer);
      default:
        return const Text('Unknown question type');
    }
  }
}

class _MCContent extends StatelessWidget {
  final SubmissionAnswer answer;

  const _MCContent({required this.answer});

  @override
  Widget build(BuildContext context) {
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
}

class _IdentificationContent extends StatelessWidget {
  final SubmissionAnswer answer;

  const _IdentificationContent({required this.answer});

  @override
  Widget build(BuildContext context) {
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
}

class _EnumerationContent extends StatelessWidget {
  final SubmissionAnswer answer;

  const _EnumerationContent({required this.answer});

  @override
  Widget build(BuildContext context) {
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
