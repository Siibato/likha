import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Normalized data for a single multiple-choice option.
class QuestionChoicePreview {
  final String text;
  final bool isCorrect;
  const QuestionChoicePreview({required this.text, required this.isCorrect});
}

/// Converts question type keys to human-readable labels.
String questionTypeLabel(String type) {
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

/// Returns the accent color used for a question type chip.
Color questionTypeColor(String type) {
  switch (type) {
    case 'multiple_choice':
      return AppColors.accentCharcoal;
    case 'identification':
      return AppColors.foregroundSecondary;
    case 'enumeration':
      return AppColors.foregroundTertiary;
    case 'essay':
      return AppColors.semanticSuccess;
    default:
      return AppColors.foregroundTertiary;
  }
}

/// Pill badge showing a question's type.
class QuestionTypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const QuestionTypeChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Renders the answer-preview section beneath a question's header row.
///
/// Used in both [QuestionCard] (published) and the view mode of [QuestionDraftCard].
/// Callers normalize their domain-specific types into the simple list parameters.
class QuestionAnswerPreview extends StatelessWidget {
  final String questionType;
  final List<QuestionChoicePreview> choices;
  final List<String> answers;

  /// Each entry is the list of acceptable answers for one enumeration item.
  final List<List<String>> enumerationItems;

  /// When true, correct choices render in [AppColors.foregroundPrimary].
  final bool highlightCorrectChoice;

  final int enumerationLimit;

  /// When true, essay questions display a "manually graded" hint row.
  final bool showEssayHint;

  const QuestionAnswerPreview({
    super.key,
    required this.questionType,
    this.choices = const [],
    this.answers = const [],
    this.enumerationItems = const [],
    this.highlightCorrectChoice = false,
    this.enumerationLimit = 4,
    this.showEssayHint = false,
  });

  @override
  Widget build(BuildContext context) {
    if (questionType == 'multiple_choice' && choices.isNotEmpty) {
      return _buildChoicePreview();
    }
    if (questionType == 'identification' && answers.isNotEmpty) {
      return _buildIdentificationPreview();
    }
    if (questionType == 'enumeration' && enumerationItems.isNotEmpty) {
      return _buildEnumerationPreview();
    }
    if (questionType == 'essay' && showEssayHint) {
      return _buildEssayHint();
    }
    return const SizedBox.shrink();
  }

  Widget _buildChoicePreview() {
    final visible = choices.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...visible.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Row(
              children: [
                Icon(
                  choice.isCorrect ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 14,
                  color: choice.isCorrect ? AppColors.semanticSuccess : AppColors.foregroundLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    choice.text.isEmpty ? '(empty)' : choice.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: highlightCorrectChoice && choice.isCorrect
                          ? AppColors.foregroundPrimary
                          : AppColors.foregroundSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (choices.length > 4)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 6),
            child: Text(
              '+${choices.length - 4} more choices',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.foregroundTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdentificationPreview() {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 10),
      child: Text(
        'Answers: ${answers.join(', ')}',
        style: const TextStyle(fontSize: 13, color: AppColors.foregroundSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEnumerationPreview() {
    final visible = enumerationItems.take(enumerationLimit).toList();
    final overflow = enumerationItems.length - enumerationLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...visible.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.value.join(' / '),
                    style: const TextStyle(fontSize: 13, color: AppColors.foregroundSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 6),
            child: Text(
              '+$overflow more items',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.foregroundTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEssayHint() {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 12),
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 16,
            color: AppColors.semanticSuccess.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          const Text(
            'Essay question - manually graded',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.foregroundSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
