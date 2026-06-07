import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/submission.dart';
import 'package:likha/presentation/widgets/mobile/teacher/assessment/override_grade_dialog.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/status_badge.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Card displaying a single student answer within the submission review screen.
///
/// Handles all question types (MC, identification, enumeration, essay) and
/// exposes essay grading and answer-override interactions via callbacks.
class SubmissionAnswerCard extends StatelessWidget {
  final SubmissionAnswer answer;
  final int index;

  /// Controller pre-created by the parent page (keyed per answer id).
  final TextEditingController essayScoreController;

  final void Function(String answerId, double points) onGradeEssay;
  final void Function(String answerId, bool isCorrect, {double? points})
      onOverride;
  final void Function(String error) onValidationError;

  const SubmissionAnswerCard({
    super.key,
    required this.answer,
    required this.index,
    required this.essayScoreController,
    required this.onGradeEssay,
    required this.onOverride,
    required this.onValidationError,
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

  void _confirmOverride(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: OverrideGradeDialog(
          answer: answer,
          onConfirm: (isCorrect, points) =>
              onOverride(answer.id, isCorrect, points: points),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEssay = answer.questionType == 'essay';
    final isPending = answer.isPendingEssayGrade;

    Color statusColor;
    IconData statusIcon;

    if (isEssay && isPending) {
      statusColor = AppColors.accentAmber;
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      final isAutoCorrect = answer.isAutoCorrect ??
          (answer.pointsAwarded >= answer.points && answer.points > 0);
      final isOverrideCorrect = answer.isOverrideCorrect;
      final effectiveCorrect = isOverrideCorrect ?? isAutoCorrect;
      final isPartial =
          answer.pointsAwarded > 0 && answer.pointsAwarded < answer.points;

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
    }

    final isOverrideCorrect = answer.isOverrideCorrect;

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
                label: isPending
                    ? 'Pending'
                    : '${answer.pointsAwarded % 1 == 0 ? answer.pointsAwarded.toInt() : answer.pointsAwarded.toStringAsFixed(1)} / ${answer.points}',
                color: statusColor,
                variant: BadgeVariant.filled,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          _buildAnswerContent(),
          if (!isEssay && isOverrideCorrect != null) ...[
            const SizedBox(height: 8),
            const StatusBadge(
              label: 'Grade overridden',
              color: AppColors.accentAmber,
              icon: Icons.edit_outlined,
              variant: BadgeVariant.filled,
            ),
          ],
          if (!isEssay && isOverrideCorrect == null && !isPending)
            const SizedBox(height: 8),
          const SizedBox(height: 12),
          if (isEssay)
            _buildEssayGradingSection(context)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmOverride(context),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Override Grade'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.foregroundPrimary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerContent() {
    switch (answer.questionType) {
      case 'multiple_choice':
        return _buildMCContent();
      case 'identification':
        return _buildIdentificationContent();
      case 'enumeration':
        return _buildEnumerationContent();
      case 'essay':
        return _buildEssayContent();
      default:
        return const Text('Unknown question type');
    }
  }

  Widget _buildMCContent() {
    final choices = answer.selectedChoices ?? [];
    if (choices.isEmpty) {
      return const Text('No answer',
          style: TextStyle(color: AppColors.foregroundTertiary));
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
                      color: c.isCorrect
                          ? AppColors.semanticSuccess
                          : AppColors.semanticError,
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

  Widget _buildIdentificationContent() {
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

  Widget _buildEnumerationContent() {
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
        final isCorrect = ea.isOverrideCorrect ?? ea.isAutoCorrect ?? ea.isCorrect;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('${idx + 1}.',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.foregroundTertiary)),
              ),
              Icon(
                isCorrect ? Icons.check : Icons.close,
                size: 16,
                color:
                    isCorrect ? AppColors.semanticSuccess : AppColors.semanticError,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ea.answerText.isNotEmpty ? ea.answerText : '(blank)',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.foregroundPrimary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEssayContent() {
    final text = answer.answerText;
    if (text == null || text.isEmpty) {
      return const Text('No response',
          style: TextStyle(color: AppColors.foregroundTertiary));
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
        style: const TextStyle(
            fontSize: 14, color: AppColors.foregroundPrimary, height: 1.5),
      ),
    );
  }

  Widget _buildEssayGradingSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: essayScoreController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Score (0 – ${answer.points})',
              labelStyle: const TextStyle(
                  fontSize: 13, color: AppColors.foregroundTertiary),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: AppColors.foregroundPrimary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            final raw = essayScoreController.text.trim();
            final pts = double.tryParse(raw);
            if (pts == null || pts < 0 || pts > answer.points) {
              onValidationError(
                  'Enter a valid score between 0 and ${answer.points}');
              return;
            }
            onGradeEssay(answer.id, pts);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.foregroundPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child:
              const Text('Save Grade', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
