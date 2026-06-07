import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AssignmentDueDatePicker extends StatelessWidget {
  final DateTime dueAt;
  final VoidCallback onTap;
  final bool enabled;

  const AssignmentDueDatePicker({
    super.key,
    required this.dueAt,
    required this.onTap,
    required this.enabled,
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due Date',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.foregroundTertiary,
          ),
          prefixIcon: const Icon(
            Icons.event_rounded,
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
          _formatDateTime(dueAt),
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