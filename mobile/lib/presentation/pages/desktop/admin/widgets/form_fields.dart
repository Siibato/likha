import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import '../utils/date_utils.dart';

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

  /// Creates a dropdown form field with standard styling
  static Widget dropdownFormField<T>({
    T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    bool enabled = true,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: inputDecoration(
        labelText ?? '',
        hintText: hintText,
        prefixIcon: prefixIcon,
        enabled: enabled,
      ),
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
      isExpanded: true,
    );
  }

  /// Creates a date picker form field
  static Widget dateFormField({
    TextEditingController? controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(DateTime)? onDateChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration(
        labelText,
        hintText: hintText ?? 'Select date',
        prefixIcon: prefixIcon ?? Icons.calendar_today_rounded,
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        enabled: enabled,
      ),
      validator: validator,
      enabled: enabled,
      readOnly: true,
      onTap: enabled ? () async {
        final date = await showDatePicker(
          context: navigatorKey.currentContext!,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          controller?.text = DesktopDateUtils.formatDateForDisplay(date);
          onDateChanged?.call(date);
        }
      } : null,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
    );
  }

  /// Creates a time picker form field
  static Widget timeFormField({
    TextEditingController? controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(TimeOfDay)? onTimeChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration(
        labelText,
        hintText: hintText ?? 'Select time',
        prefixIcon: prefixIcon ?? Icons.schedule_rounded,
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        enabled: enabled,
      ),
      validator: validator,
      enabled: enabled,
      readOnly: true,
      onTap: enabled ? () async {
        final time = await showTimePicker(
          context: navigatorKey.currentContext!,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          controller?.text = time.format(navigatorKey.currentContext!);
          onTimeChanged?.call(time);
        }
      } : null,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
    );
  }

  /// Creates a switch form field with label
  static Widget switchFormField({
    required bool value,
    required void Function(bool) onChanged,
    required String labelText,
    bool enabled = true,
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.foregroundPrimary,
        ),
      ],
    );
  }

  /// Creates a checkbox form field with label
  static Widget checkboxFormField({
    required bool value,
    required void Function(bool?) onChanged,
    required String labelText,
    bool enabled = true,
    String? subtitle,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.foregroundPrimary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labelText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Creates a standard button for desktop forms
  static Widget button({
    required VoidCallback onPressed,
    required String text,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
    bool fullWidth = false,
  }) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null 
            ? isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, size: 18)
            : isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : null,
        label: Text(text),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.foregroundPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null 
            ? isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, size: 18)
            : isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : null,
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundPrimary,
          side: const BorderSide(color: AppColors.foregroundPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
        ),
      );
    }
  }

  /// Creates a search field with standard styling
  static Widget searchField({
    TextEditingController? controller,
    String? hintText,
    void Function(String)? onChanged,
    void Function()? onClear,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration(
        '',
        hintText: hintText ?? 'Search...',
        prefixIcon: Icons.search_rounded,
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: onClear ?? () {
                  controller?.clear();
                  onChanged?.call('');
                },
              )
            : null,
        enabled: enabled,
      ),
      onChanged: onChanged,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.foregroundPrimary,
      ),
    );
  }
}

// Global key for accessing context in static methods
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
