import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class TosEmptyCompetencies extends StatelessWidget {
  final String message;

  const TosEmptyCompetencies({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.foregroundSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
