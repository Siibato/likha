import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_card.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_draft.dart';

class AssessmentQuestionsSection extends StatelessWidget {
  final List<QuestionDraft> questions;
  final bool isLoading;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final VoidCallback onQuestionsChanged;
  final VoidCallback? onSaveQuestions;

  const AssessmentQuestionsSection({
    super.key,
    required this.questions,
    required this.isLoading,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onQuestionsChanged,
    required this.onSaveQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (questions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'No questions added yet.\nTap the button below to add a question.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF999999),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return QuestionDraftCard(
            index: index,
            question: question,
            onRemove: () => onRemoveQuestion(index),
            onChanged: onQuestionsChanged,
          );
        }),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onAddQuestion,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Question'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2B2B2B),
            side: const BorderSide(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}