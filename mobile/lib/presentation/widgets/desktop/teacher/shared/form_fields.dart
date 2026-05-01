import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Utility class for creating consistent form fields across desktop pages
class DesktopFormField {
  /// Creates a standard input decoration for desktop form fields
  static InputDecoration inputDecoration(String label, {
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundTertiary,
      ),
      labelStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundSecondary,
      ),
      prefixIcon: prefixIcon != null ? Icon(
        prefixIcon,
        color: AppColors.foregroundTertiary,
        size: 20,
      ) : null,
      suffixIcon: suffixIcon,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.foregroundPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: enabled ? Colors.white : AppColors.backgroundTertiary,
    );
  }

  /// Creates a text form field with standard styling
  static Widget textFormField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    int? maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration(
        labelText ?? '',
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
        enabled: enabled,
      ),
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
    );
  }

  /// Creates a number-only text field
  static Widget numberFormField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    bool enabled = true,
    IconData? prefixIcon,
    String? errorText,
  }) {
    return textFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      prefixIcon: prefixIcon,
      errorText: errorText,
    );
  }

  /// Creates a dropdown form field with standard styling
  static Widget dropdownFormField<T>({
    T? value,
    required List<DropdownMenuItem<T>> items,
    String? labelText,
    String? hintText,
    void Function(T?)? onChanged,
    String? Function(T?)? validator,
    bool enabled = true,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: inputDecoration(
        labelText ?? '',
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon ?? (enabled ? const Icon(
          Icons.arrow_drop_down_rounded,
          color: AppColors.foregroundSecondary,
        ) : null),
        errorText: errorText,
        enabled: enabled,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      isExpanded: true,
    );
  }

  /// Creates a date/time picker field
  static Widget dateTimeField({
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
    String? formatPattern,
    bool enabled = true,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    String displayDateTime(DateTime dt) {
      if (formatPattern != null) {
        // Custom format pattern could be implemented here
        // For now, using default formatting
      }
      
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = dt.hour > 12
          ? dt.hour - 12
          : dt.hour == 0
              ? 12
              : dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}  $hour:$minute $period';
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: inputDecoration(label).copyWith(
          suffixIcon: suffixIcon ?? (enabled ? const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.foregroundSecondary,
          ) : null),
          fillColor: enabled ? Colors.white : AppColors.backgroundTertiary,
        ),
        child: Text(
          displayDateTime(dateTime),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.foregroundDark : AppColors.foregroundTertiary,
          ),
        ),
      ),
    );
  }

  /// Creates a date-only picker field
  static Widget dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    bool enabled = true,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? formatPattern,
  }) {
    String formatDate(DateTime dt) {
      if (formatPattern == 'yyyy-MM-dd') {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day}/${dt.year}';
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: inputDecoration(label).copyWith(
          suffixIcon: suffixIcon ?? (enabled ? const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.foregroundSecondary,
            size: 18,
          ) : null),
          fillColor: enabled ? Colors.white : AppColors.backgroundTertiary,
        ),
        child: Text(
          formatDate(date),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.foregroundDark : AppColors.foregroundTertiary,
          ),
        ),
      ),
    );
  }

  /// Creates a switch list tile with consistent styling
  static Widget switchListTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    bool enabled = true,
    EdgeInsets? contentPadding,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? AppColors.foregroundDark : AppColors.foregroundTertiary,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.foregroundTertiary,
        ),
      ) : null,
      contentPadding: contentPadding ?? EdgeInsets.zero,
      activeColor: AppColors.foregroundPrimary,
    );
  }

  /// Creates a search field with consistent styling
  static Widget searchField({
    TextEditingController? controller,
    String? hintText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      decoration: inputDecoration(
        '',
        hintText: hintText ?? 'Search...',
        prefixIcon: Icons.search_rounded,
        errorText: errorText,
        enabled: enabled,
      ).copyWith(
        labelText: null,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
    );
  }

  /// Creates a styled button for form actions
  static Widget primaryButton({
    required VoidCallback onPressed,
    required String label,
    bool isLoading = false,
    IconData? icon,
    bool enabled = true,
    double? height,
    double? width,
  }) {
    return SizedBox(
      height: height ?? 48,
      width: width,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.foregroundPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.backgroundTertiary,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Creates a secondary button for form actions
  static Widget secondaryButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
    bool enabled = true,
    double? height,
    double? width,
  }) {
    return SizedBox(
      height: height ?? 48,
      width: width,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundPrimary,
          side: const BorderSide(color: AppColors.foregroundPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension methods for common form field patterns
extension DesktopFormFieldExtensions on DesktopFormField {
  /// Creates a required text field with basic validation
  static Widget requiredText({
    TextEditingController? controller,
    required String label,
    String? hintText,
    IconData? prefixIcon,
    String? errorText,
  }) {
    return DesktopFormField.textFormField(
      controller: controller,
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      errorText: errorText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  /// Creates a required number field with basic validation
  static Widget requiredNumber({
    TextEditingController? controller,
    required String label,
    String? hintText,
    IconData? prefixIcon,
    String? errorText,
    int? min,
    int? max,
  }) {
    return DesktopFormField.numberFormField(
      controller: controller,
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      errorText: errorText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        final number = int.tryParse(value.trim());
        if (number == null) {
          return 'Please enter a valid number';
        }
        if (min != null && number < min) {
          return 'Must be at least $min';
        }
        if (max != null && number > max) {
          return 'Must be at most $max';
        }
        return null;
      },
    );
  }
}
