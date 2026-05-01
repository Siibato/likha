import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assessments/entities/question.dart';

class QuestionReorderList extends StatelessWidget {
  final List<Question> reorderBuffer;
  final Map<String, int> questionAnimatingIndices;
  final AnimationController animationController;
  final void Function(int) onShowMoveDialog;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const QuestionReorderList({
    super.key,
    required this.reorderBuffer,
    required this.questionAnimatingIndices,
    required this.animationController,
    required this.onShowMoveDialog,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentCharcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with cancel and done buttons
            Row(
              children: [
                Text(
                  'Questions (${reorderBuffer.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foregroundSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Animated question list
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return Column(
                  children: [
                    ...reorderBuffer.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      final oldIndex = questionAnimatingIndices[question.id] ?? index;
                      final offset = (oldIndex - index) * 92.0; // Card height
                      final animValue = animationController.value;
                      final currentOffset = offset * (1 - animValue);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Transform.translate(
                          offset: Offset(0, currentOffset),
                          child: GestureDetector(
                            onTap: () => onShowMoveDialog(index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentCharcoal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundTertiary,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.foregroundPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            question.questionText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: AppColors.foregroundPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          _QuestionTypeChip(
                                            label: _questionTypeLabel(question.questionType),
                                            color: _questionTypeColor(question.questionType),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.foregroundLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
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

  Color _questionTypeColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return AppColors.accentCharcoal;
      case 'identification':
        return AppColors.foregroundSecondary;
      case 'enumeration':
        return AppColors.foregroundTertiary;
      default:
        return AppColors.foregroundTertiary;
    }
  }
}

class _QuestionTypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _QuestionTypeChip({
    required this.label,
    required this.color,
  });

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
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
