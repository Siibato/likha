import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Cross-platform search bar for Likha LMS.
///
/// Uses the same 2-layer shell pattern as [StyledTextField].
/// Replaces [AdminSearchBar] (currently in `admin/account/widgets/`) which
/// is also used by teacher pages — making it not truly admin-specific.
///
/// Usage:
/// ```dart
/// AppSearchBar(
///   hint: 'Search classes...',
///   onChanged: (q) => setState(() => _query = q),
/// )
/// ```
class AppSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String hint;
  final bool enabled;
  final EdgeInsets? padding;
  final VoidCallback? onClear;

  const AppSearchBar({
    super.key,
    this.onChanged,
    this.controller,
    this.hint = 'Search...',
    this.enabled = true,
    this.padding,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentCharcoal,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.inputLabel,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.foregroundTertiary,
                size: 22,
              ),
              suffixIcon: onClear != null && (controller?.text.isNotEmpty ?? false)
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AppColors.foregroundTertiary,
                        size: 20,
                      ),
                      onPressed: () {
                        controller?.clear();
                        onClear?.call();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.accentCharcoal,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
