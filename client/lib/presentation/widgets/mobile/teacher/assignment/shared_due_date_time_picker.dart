import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class SharedDueDateTimePicker extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final IconData icon;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  const SharedDueDateTimePicker({
    super.key,
    required this.label,
    required this.dateTime,
    required this.icon,
    required this.enabled,
    required this.onChanged,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year} $hour:$minute $period';
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentCharcoal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.accentCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dateTime),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (time == null || !context.mounted) return;

    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _pickDateTime(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.foregroundTertiary,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.foregroundSecondary,
            size: 20,
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.foregroundSecondary,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          enabled: enabled,
        ),
        child: Text(
          _formatDateTime(dateTime),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.accentCharcoal,
          ),
        ),
      ),
    );
  }
}
