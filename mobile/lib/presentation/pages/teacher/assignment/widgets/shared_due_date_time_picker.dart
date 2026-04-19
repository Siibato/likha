import 'package:flutter/material.dart';

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
              primary: Color(0xFF2B2B2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2B2B2B),
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
              primary: Color(0xFF2B2B2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2B2B2B),
              secondary: Color(0xFF2B2B2B),
              tertiary: Color(0xFF2B2B2B),
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
            color: Color(0xFF999999),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF666666),
            size: 20,
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFF666666),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
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
            color: Color(0xFF2B2B2B),
          ),
        ),
      ),
    );
  }
}
