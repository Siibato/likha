import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class EmptyClassesState extends StatelessWidget {
  const EmptyClassesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 64, color: AppColors.foregroundLight),
          SizedBox(height: 16),
          Text(
            'No classes yet',
            style: TextStyle(fontSize: 16, color: AppColors.foregroundTertiary),
          ),
        ],
      ),
    );
  }
}
