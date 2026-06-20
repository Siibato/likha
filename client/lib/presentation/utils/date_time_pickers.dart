import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

Future<DateTime?> pickDateTime(
  BuildContext context, {
  required DateTime current,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime.now().subtract(const Duration(days: 7)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentCharcoal,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.accentCharcoal,
        ),
      ),
      child: child!,
    ),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current),
    initialEntryMode: TimePickerEntryMode.input,
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentCharcoal,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.accentCharcoal,
          secondary: AppColors.accentCharcoal,
          tertiary: AppColors.accentCharcoal,
          onTertiary: Colors.white,
        ),
      ),
      child: child!,
    ),
  );
  if (time == null || !context.mounted) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
