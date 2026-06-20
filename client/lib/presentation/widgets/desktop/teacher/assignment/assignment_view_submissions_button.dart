import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/teacher/assignment/assignment_submissions_page.dart';

/// Button that navigates to the assignment submissions list.
class AssignmentViewSubmissionsButton extends StatelessWidget {
  final String assignmentId;
  final String title;
  final int totalPoints;

  const AssignmentViewSubmissionsButton({
    super.key,
    required this.assignmentId,
    required this.title,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AssignmentSubmissionsPage(
                assignmentId: assignmentId,
                title: title,
                totalPoints: totalPoints,
              ),
            ),
          );
        },
        icon: const Icon(Icons.list_alt_rounded, size: 18),
        label: const Text('View Submissions'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundDark,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
