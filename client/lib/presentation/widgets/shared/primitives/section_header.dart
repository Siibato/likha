import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Shared mobile page section header for Likha LMS.
///
/// Generalises [ClassSectionHeader] which is used across 33 files.
/// Provides a white rounded-bottom container with title, optional back button,
/// and optional trailing widget slot.
///
/// Usage:
/// ```dart
/// SectionHeader(
///   title: 'My Classes',
///   showBackButton: true,
///   trailing: IconButton(...),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final Widget? trailing;
  final double? fontSize;
  final VoidCallback? onBack;

  const SectionHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.trailing,
    this.fontSize,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 12, 12),
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.foregroundDark,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title,
              style: fontSize != null
                  ? AppTextStyles.sectionTitle.copyWith(fontSize: fontSize)
                  : AppTextStyles.sectionTitle.copyWith(
                      fontSize: 28,
                      color: AppColors.accentCharcoal,
                    ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
