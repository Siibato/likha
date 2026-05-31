import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class EmptySearchClassesState extends StatelessWidget {
  final String searchQuery;

  const EmptySearchClassesState({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: AppColors.foregroundLight),
          const SizedBox(height: 16),
          Text(
            'No classes match "$searchQuery"',
            style: const TextStyle(fontSize: 16, color: AppColors.foregroundTertiary),
          ),
        ],
      ),
    );
  }
}
