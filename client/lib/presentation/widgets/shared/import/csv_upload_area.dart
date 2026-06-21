import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class CsvUploadArea extends StatelessWidget {
  final String? selectedFilePath;
  final VoidCallback onPickFile;
  final String label;

  const CsvUploadArea({
    super.key,
    this.selectedFilePath,
    required this.onPickFile,
    this.label = 'Upload CSV File',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedFilePath != null
                  ? Icons.check_circle_outline_rounded
                  : Icons.upload_file_outlined,
              size: 48,
              color: AppColors.accentCharcoal,
            ),
            const SizedBox(height: 16),
            Text(
              selectedFilePath != null
                  ? 'File selected: ${selectedFilePath!.split('/').last}'
                  : label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to select a CSV file',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.foregroundDark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
