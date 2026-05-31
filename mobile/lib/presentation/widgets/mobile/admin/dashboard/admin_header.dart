import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class AdminHeader extends StatelessWidget {
  final String fullName;

  const AdminHeader({
    super.key,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.foregroundTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.foregroundDark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}