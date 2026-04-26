import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class QuestionTypeBadge extends StatelessWidget {
  final String questionType;

  const QuestionTypeBadge({super.key, required this.questionType});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;

    switch (questionType) {
      case 'multiple_choice':
        label = 'Multiple Choice';
        icon = Icons.radio_button_checked_rounded;
        break;
      case 'identification':
        label = 'Identification';
        icon = Icons.short_text_rounded;
        break;
      case 'enumeration':
        label = 'Enumeration';
        icon = Icons.format_list_numbered_rounded;
        break;
      case 'essay':
        label = 'Essay';
        icon = Icons.edit_note_rounded;
        break;
      default:
        label = questionType;
        icon = Icons.help_outline_rounded;
    }

    const Color backgroundColor = AppColors.accentCharcoal;
    const Color foregroundColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Text(
            'Question type cannot be changed',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
