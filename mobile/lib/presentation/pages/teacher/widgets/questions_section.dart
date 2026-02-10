import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_card.dart';

class QuestionsSection extends StatelessWidget {
  final List<Question> questions;
  final bool canEdit;
  final bool isPublished;
  final int submissionCount;
  final VoidCallback? onAddQuestion;
  final Function(Question)? onEditQuestion;
  final Function(Question)? onDeleteQuestion;

  const QuestionsSection({
    super.key,
    required this.questions,
    required this.canEdit,
    required this.isPublished,
    required this.submissionCount,
    this.onAddQuestion,
    this.onEditQuestion,
    this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Questions (${questions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (canEdit)
                ElevatedButton.icon(
                  onPressed: onAddQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2B2B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          if (submissionCount > 0 && canEdit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFE0B2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFA726),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This assessment has $submissionCount submission(s). Editing questions may affect scores.',
                      style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isPublished) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFE0B2),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFFFA726),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This assessment is published. Questions and details can no longer be edited.',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (questions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No questions added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return QuestionCard(
                index: index,
                question: question,
                canEdit: canEdit,
                onEdit: canEdit && onEditQuestion != null
                    ? () => onEditQuestion!(question)
                    : null,
                onDelete: canEdit && onDeleteQuestion != null
                    ? () => onDeleteQuestion!(question)
                    : null,
              );
            }),
        ],
      ),
    );
  }
}