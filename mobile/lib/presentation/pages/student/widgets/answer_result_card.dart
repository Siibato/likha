import 'package:flutter/material.dart';
import 'package:likha/domain/assessments/entities/submission.dart';

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
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = answer.isCorrect == true;
    final isPartial =
        answer.pointsAwarded > 0 && answer.pointsAwarded < answer.points;
    final statusIcon = isCorrect
        ? Icons.check_circle_rounded
        : isPartial
            ? Icons.remove_circle_rounded
            : Icons.cancel_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            _buildHeader(statusIcon, isCorrect, isPartial),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                _questionTypeLabel(answer.questionType),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFAAAAAA),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 16),
            _buildAnswerDetail(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(IconData statusIcon, bool isCorrect, bool isPartial) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          statusIcon,
          color: const Color(0xFF666666),
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question $questionNumber',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                answer.questionText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202020),
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
            ),
          ),
          child: Text(
            '${answer.pointsAwarded % 1 == 0 ? answer.pointsAwarded.toInt() : answer.pointsAwarded.toStringAsFixed(1)} / ${answer.points}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnswerRow(
          label: 'Your answer',
          value: selectedChoices.isNotEmpty
              ? selectedChoices.join(', ')
              : 'No answer',
          isCorrect: answer.isCorrect,
        ),
        if (answer.isCorrect != true) ...[
          const SizedBox(height: 12),
          _AnswerRow(
            label: 'Correct answer',
            value: correctAnswers.isNotEmpty ? correctAnswers.join(', ') : '-',
            isHighlighted: true,
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
        _AnswerRow(
          label: 'Your answer',
          value: answer.answerText?.isNotEmpty == true
              ? answer.answerText!
              : 'No answer',
          isCorrect: answer.isCorrect,
        ),
        if (answer.isCorrect != true) ...[
          const SizedBox(height: 12),
          _AnswerRow(
            label: 'Correct answer',
            value: correctAnswers.isNotEmpty ? correctAnswers.join(' or ') : '-',
            isHighlighted: true,
          ),
        ],
      ],
    );
  }
}

class _EnumerationAnswerDetail extends StatelessWidget {
  final StudentAnswerResult answer;

  const _EnumerationAnswerDetail({required this.answer});

  @override
  Widget build(BuildContext context) {
    final enumAnswers = answer.enumerationAnswers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your answers:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        ...enumAnswers.asMap().entries.map((entry) {
          final idx = entry.key;
          final enumAnswer = entry.value;
          final itemCorrect = enumAnswer.isCorrect == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${idx + 1}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Icon(
                    itemCorrect ? Icons.check_rounded : Icons.close_rounded,
                    size: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    enumAnswer.answerText.isNotEmpty
                        ? enumAnswer.answerText
                        : '(blank)',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF2B2B2B),
                      fontWeight: FontWeight.w500,
                      decoration: itemCorrect
                          ? null
                          : TextDecoration.lineThrough,
                      decorationColor: const Color(0xFF999999),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (answer.isCorrect != true &&
            answer.correctAnswers != null &&
            answer.correctAnswers!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _AnswerRow(
            label: 'Acceptable answers',
            value: answer.correctAnswers!.join(', '),
            isHighlighted: true,
          ),
        ],
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final bool? isCorrect;
  final bool isHighlighted;

  const _AnswerRow({
    required this.label,
    required this.value,
    this.isCorrect,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: isHighlighted
                ? BoxDecoration(
                    color: const Color(0xFFFFF8ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFFFBD59).withOpacity(0.3),
                    ),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF202020),
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}