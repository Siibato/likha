import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/shared/cards/base_info_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';

class AnswerResultCard extends StatelessWidget {
  final StudentAnswerResult answer;
  final int questionNumber;

  const AnswerResultCard({
    super.key,
    required this.answer,
    required this.questionNumber,
  });

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

  @override
  Widget build(BuildContext context) {
    final isPending = answer.isPendingEssayGrade;
    final isAutoCorrect = answer.isCorrect == true;
    final isPartial = answer.pointsAwarded > 0 && answer.pointsAwarded < answer.points;

    Color statusColor;
    IconData statusIcon;
    if (isPending) {
      statusColor = AppColors.accentAmber;
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (isAutoCorrect) {
      statusColor = AppColors.semanticSuccess;
      statusIcon = Icons.check_circle;
    } else if (isPartial) {
      statusColor = AppColors.foregroundSecondary;
      statusIcon = Icons.remove_circle;
    } else {
      statusColor = AppColors.semanticError;
      statusIcon = Icons.cancel;
    }

    return BaseInfoCard(
      title: 'Q$questionNumber. ${answer.questionText}',
      subtitle: '${_questionTypeLabel(answer.questionType)} - ${answer.points} pt${answer.points != 1 ? 's' : ''}',
      icon: Icon(statusIcon, color: statusColor),
      trailing: StatusBadge(
        label: isPending
            ? 'Pending'
            : '${answer.pointsAwarded % 1 == 0 ? answer.pointsAwarded.toInt() : answer.pointsAwarded.toStringAsFixed(1)} / ${answer.points}',
        color: statusColor,
        variant: BadgeVariant.filled,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnswerDetail(),
          if (isPending) ...[
            const SizedBox(height: 8),
            const StatusBadge(
              label: 'Awaiting teacher grading',
              color: AppColors.accentAmber,
              icon: Icons.schedule,
              variant: BadgeVariant.filled,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerDetail() {
    switch (answer.questionType) {
      case 'multiple_choice':
        return _MCAnswerDetail(answer: answer);
      case 'identification':
        return _IdentificationAnswerDetail(answer: answer);
      case 'enumeration':
        return _EnumerationAnswerDetail(answer: answer);
      case 'essay':
        return _EssayAnswerDetail(answer: answer);
      default:
        return const Text('Unknown question type');
    }
  }
}

class _MCAnswerDetail extends StatelessWidget {
  final StudentAnswerResult answer;

  const _MCAnswerDetail({required this.answer});

  @override
  Widget build(BuildContext context) {
    final selectedChoices = answer.selectedChoices ?? [];
    final correctAnswers = answer.correctAnswers ?? [];

    if (selectedChoices.isEmpty) {
      return const Text('No answer', style: TextStyle(color: AppColors.foregroundTertiary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...selectedChoices.map((choice) {
          final isCorrect = correctAnswers.contains(choice);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isCorrect ? AppColors.semanticSuccess : AppColors.semanticError,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    choice,
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
        if (answer.isCorrect != true && correctAnswers.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Correct answer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.accentAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              correctAnswers.join(', '),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IdentificationAnswerDetail extends StatelessWidget {
  final StudentAnswerResult answer;

  const _IdentificationAnswerDetail({required this.answer});

  @override
  Widget build(BuildContext context) {
    final correctAnswers = answer.correctAnswers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer.answerText?.isNotEmpty == true
              ? 'Answer: ${answer.answerText}'
              : 'No answer',
          style: TextStyle(
            fontSize: 14,
            color: answer.answerText?.isNotEmpty == true
                ? AppColors.foregroundPrimary
                : AppColors.foregroundTertiary,
          ),
        ),
        if (answer.isCorrect != true && correctAnswers.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Correct answer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.accentAmber.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              correctAnswers.join(' or '),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EssayAnswerDetail extends StatelessWidget {
  final StudentAnswerResult answer;

  const _EssayAnswerDetail({required this.answer});

  @override
  Widget build(BuildContext context) {
    final text = answer.answerText;
    if (text == null || text.isEmpty) {
      return const Text('No response', style: TextStyle(color: AppColors.foregroundTertiary));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.foregroundPrimary, height: 1.5),
      ),
    );
  }
}

class _EnumerationAnswerDetail extends StatelessWidget {
  final StudentAnswerResult answer;

  const _EnumerationAnswerDetail({required this.answer});

  @override
  Widget build(BuildContext context) {
    final enumAnswers = answer.enumerationAnswers ?? [];
    if (enumAnswers.isEmpty) {
      return const Text('No answers', style: TextStyle(color: AppColors.foregroundTertiary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...enumAnswers.asMap().entries.map((entry) {
          final idx = entry.key;
          final ea = entry.value;
          final isCorrect = ea.isCorrect == true;
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
        if (answer.isCorrect != true &&
            answer.correctAnswers != null &&
            answer.correctAnswers!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Acceptable answers',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: answer.correctAnswers!.map((ans) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.accentAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                ans,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundPrimary,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}

