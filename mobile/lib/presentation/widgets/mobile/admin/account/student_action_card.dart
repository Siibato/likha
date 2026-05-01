import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/user.dart';

class StudentActionCard extends StatelessWidget {
  final User student;
  final bool isParticipant;
  final bool isLoading;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const StudentActionCard({
    super.key,
    required this.student,
    required this.isParticipant,
    this.isLoading = false,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with initial
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Student info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foregroundDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${student.username}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action button area
                  _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accentCharcoal,
        ),
      );
    }

    if (isParticipant) {
      return IconButton(
        iconSize: 22,
        splashRadius: 20,
        icon: const Icon(Icons.remove_circle_outline_rounded),
        color: AppColors.semanticError,
        onPressed: onRemove,
      );
    }

    return IconButton(
      iconSize: 22,
      splashRadius: 20,
      icon: const Icon(Icons.add_circle_outline_rounded),
      color: AppColors.semanticSuccessAlt,
      onPressed: onAdd,
    );
  }
}
