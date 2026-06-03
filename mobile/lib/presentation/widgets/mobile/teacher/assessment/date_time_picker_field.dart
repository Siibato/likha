import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class DateTimePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const DateTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
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
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.foregroundTertiary,
          ),
          prefixIcon: Icon(icon, color: AppColors.foregroundSecondary, size: 20),
          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.foregroundSecondary,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
          enabled: enabled,
        ),
        child: Text(
          _formatDateTime(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.foregroundPrimary : AppColors.foregroundTertiary,
          ),
        ),
      ),
    );
  }
}