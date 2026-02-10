import 'package:flutter/material.dart';

class QuestionTypeBadge extends StatelessWidget {
  final String questionType;

  const QuestionTypeBadge({super.key, required this.questionType});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;

    switch (questionType) {
      case 'multiple_choice':
        label = 'Multiple Choice';
        icon = Icons.radio_button_checked_rounded;
        color = const Color(0xFF42A5F5);
        break;
      case 'identification':
        label = 'Identification';
        icon = Icons.short_text_rounded;
        color = const Color(0xFF9C27B0);
        break;
      case 'enumeration':
        label = 'Enumeration';
        icon = Icons.format_list_numbered_rounded;
        color = const Color(0xFF26A69A);
        break;
      default:
        label = questionType;
        icon = Icons.help_outline_rounded;
        color = const Color(0xFF999999);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Text(
            'Question type cannot be changed',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}