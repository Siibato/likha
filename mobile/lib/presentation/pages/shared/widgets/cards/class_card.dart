import 'package:flutter/material.dart';
import 'base_card.dart';
import '../primitives/card_icon_slot.dart';
import '../primitives/chevron_trailing.dart';
import '../tokens/app_text_styles.dart';

/// A unified class card used by both teachers and students.
///
/// Displays subject icon, class title, and caller-provided subtitle (student count for
/// teachers, teacher name for students). Uses [BaseCard] for consistent styling.
class ClassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isAdvisory;

  const ClassCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isAdvisory = false,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      child: Row(
        children: [
          CardIconSlot.md(icon: _getSubjectIcon(title)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitleMd,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.cardSubtitleMd,
                ),
                if (isAdvisory) ...[
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: Color(0xFF4CAF50)),
                      SizedBox(width: 3),
                      Text(
                        'Advisory',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ChevronTrailing.large(),
        ],
      ),
    );
  }

  /// Returns the appropriate icon for the class subject based on the title.
  /// Uses full subject mapping for consistency across roles.
  IconData _getSubjectIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('math')) return Icons.functions_rounded;
    if (t.contains('science')) return Icons.science_outlined;
    if (t.contains('art')) return Icons.palette_outlined;
    if (t.contains('english') || t.contains('literature')) {
      return Icons.menu_book_rounded;
    }
    if (t.contains('history')) return Icons.history_edu_rounded;
    if (t.contains('music')) return Icons.music_note_rounded;
    return Icons.class_outlined;
  }
}
