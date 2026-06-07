import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class StudentListItem extends StatelessWidget {
  final String studentId;
  final String fullName;
  final String username;
  final VoidCallback onRemove;

  const StudentListItem({
    super.key,
    required this.studentId,
    required this.fullName,
    required this.username,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.backgroundTertiary,
            child: Text(
              fullName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.foregroundDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            fullName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundDark,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(
            username,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundTertiary,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.semanticError,
            ),
            onPressed: onRemove,
          ),
        ),
      ),
    );
  }
}