import 'package:flutter/material.dart';
import 'package:likha/presentation/pages/teacher/widgets/question_draft.dart';

class AssessmentReviewStep extends StatelessWidget {
  final String title;
  final String description;
  final int timeLimitMinutes;
  final DateTime openAt;
  final DateTime closeAt;
  final bool showResultsImmediately;
  final List<QuestionDraft> questions;
  final VoidCallback onFinish;

  const AssessmentReviewStep({
    super.key,
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    required this.openAt,
    required this.closeAt,
    required this.showResultsImmediately,
    required this.questions,
    required this.onFinish,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $period';
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
        return const Color(0xFF42A5F5);
      case 'identification':
        return const Color(0xFF9C27B0);
      case 'enumeration':
        return const Color(0xFF26A69A);
      default:
        return const Color(0xFF999999);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Assessment Details Card
        Container(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                  letterSpacing: -0.4,
                ),
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.timer_rounded,
                label: 'Time Limit',
                value: '$timeLimitMinutes minutes',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.star_outline_rounded,
                label: 'Total Points',
                value: '$totalPoints points',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.help_outline_rounded,
                label: 'Questions',
                value: '${questions.length}',
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Opens',
                value: _formatDateTime(openAt),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.event_rounded,
                label: 'Closes',
                value: _formatDateTime(closeAt),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.visibility_outlined,
                label: 'Show Results',
                value: showResultsImmediately ? 'Immediately' : 'After release',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Questions Section
        Container(
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
              Text(
                'Questions (${questions.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202020),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              ...questions.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                return _QuestionPreviewCard(
                  index: i,
                  question: q,
                  typeLabel: _questionTypeLabel(q.type),
                  typeColor: _questionTypeColor(q.type),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onFinish,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2B2B2B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Save as Draft',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF666666),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2B2B2B),
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final int index;
  final QuestionDraft question;
  final String typeLabel;
  final Color typeColor;

  const _QuestionPreviewCard({
    required this.index,
    required this.question,
    required this.typeLabel,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2B2B),
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
                        fontSize: 15,
                        color: Color(0xFF202020),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${question.points} pt${question.points == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (question.type == 'multiple_choice') ...[
            const SizedBox(height: 10),
            ...question.choices.map((c) => Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4),
                  child: Row(
                    children: [
                      Icon(
                        c.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 14,
                        color: c.isCorrect
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFCCCCCC),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (question.type == 'identification') ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                'Answers: ${question.acceptableAnswers.where((a) => a.trim().isNotEmpty).join(', ')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ],
          if (question.type == 'enumeration') ...[
            const SizedBox(height: 10),
            ...question.enumerationItems.asMap().entries.map((ie) => Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4),
                  child: Text(
                    'Item ${ie.key + 1}: ${ie.value.answers.where((a) => a.trim().isNotEmpty).join(', ')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}