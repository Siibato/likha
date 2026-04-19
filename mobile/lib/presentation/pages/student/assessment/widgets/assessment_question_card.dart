// lib/presentation/pages/student/widgets/assessment_question_card.dart
import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/question.dart';
import 'package:likha/presentation/utils/formatters.dart';
import 'package:likha/presentation/pages/student/assessment/widgets/assessment_question_input.dart';

class AssessmentQuestionCard extends StatelessWidget {
  final StudentQuestion question;
  final int questionNumber;
  final Map<String, Set<String>> selectedChoices;
  final Map<String, TextEditingController> textControllers;
  final Map<String, Map<int, TextEditingController>> enumControllers;
  final Function(String, Set<String>) onChoicesChanged;
  final Function(String, String) onTextChanged;
  final Function(String, int, String) onEnumChanged;

  const AssessmentQuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.selectedChoices,
    required this.textControllers,
    required this.enumControllers,
    required this.onChoicesChanged,
    required this.onTextChanged,
    required this.onEnumChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 16),
            AssessmentQuestionInput(
              question: question,
              selectedChoices: selectedChoices,
              textController: textControllers[question.id],
              enumControllers: enumControllers[question.id],
              onChoicesChanged: (choices) =>
                  onChoicesChanged(question.id, choices),
              onTextChanged: (text) => onTextChanged(question.id, text),
              onEnumChanged: (index, text) =>
                  onEnumChanged(question.id, index, text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$questionNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202020),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${question.points} point${question.points != 1 ? 's' : ''} • ${Formatters.questionTypeLabel(question.questionType)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}