import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Centred timestamp label showing when the submission was submitted.
class AssignmentSubmissionInfo extends StatelessWidget {
  final DateTime submittedAt;

  const AssignmentSubmissionInfo({super.key, required this.submittedAt});

  String _formatDateTime(DateTime dt) {
    final months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Submitted: ${_formatDateTime(submittedAt)}',
        style: const TextStyle(
          color: AppColors.foregroundTertiary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
