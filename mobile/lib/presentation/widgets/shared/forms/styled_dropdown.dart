import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// A styled dropdown menu that matches the app's design system.
///
/// Generic over any type [T], providing a 2-layer container appearance
/// consistent with other styled form inputs.
class StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const StyledDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: AppColors.backgroundSecondary,
        splashColor: AppColors.backgroundSecondary,
      ),
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
          child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            validator: validator,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: item.child,
                ),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.foregroundTertiary,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.foregroundTertiary,
                size: 22,
              ),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.semanticError,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.semanticError,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundDark,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.foregroundTertiary,
            ),
            dropdownColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
