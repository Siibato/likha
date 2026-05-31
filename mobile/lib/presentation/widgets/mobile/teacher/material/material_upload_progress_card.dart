import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

/// Inline card showing the progress of an in-flight file upload.
///
/// Displays the file name, percentage label, and a linear progress bar.
/// Pass [progress] as 0.0–1.0; a null/zero value renders an indeterminate bar.
class MaterialUploadProgressCard extends StatelessWidget {
  final String fileName;
  final double progress;

  const MaterialUploadProgressCard({
    super.key,
    required this.fileName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.accentCharcoal,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Uploading $fileName...',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCharcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.borderLight,
              color: AppColors.accentCharcoal,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
