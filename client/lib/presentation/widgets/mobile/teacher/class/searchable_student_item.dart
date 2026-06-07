import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class SearchableStudentItem extends StatelessWidget {
  final String fullName;
  final String username;
  final String accountStatus;
  final bool isParticipant;
  final VoidCallback onAction;

  const SearchableStudentItem({
    super.key,
    required this.fullName,
    required this.username,
    required this.accountStatus,
    required this.isParticipant,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.accentCharcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 2.5),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
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
                color: AppColors.accentCharcoal,
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
            '$username • $accountStatus',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foregroundTertiary,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              isParticipant
                  ? Icons.remove_circle_rounded
                  : Icons.add_circle_rounded,
              color: isParticipant
                  ? AppColors.semanticError
                  : AppColors.accentCharcoal,
            ),
            onPressed: onAction,
          ),
        ),
      ),
    );
  }
}