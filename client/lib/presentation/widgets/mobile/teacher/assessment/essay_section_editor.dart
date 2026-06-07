import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Static info box shown for essay-type questions.
///
/// No editing UI — essays are graded manually after submission.
class EssaySectionEditor extends StatelessWidget {
  const EssaySectionEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note_rounded, size: 20, color: AppColors.foregroundTertiary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Essay Question',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Students will write a free-form essay response. No answer key required — you will grade this manually after submission.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
