import 'package:flutter/material.dart';

/// Dialog showing file upload progress with linear progress bar and percentage
class UploadProgressDialog extends StatelessWidget {
  final String fileName;
  final double progress; // 0.0 to 1.0
  final VoidCallback? onCancel;

  const UploadProgressDialog({
    super.key,
    required this.fileName,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Color(0xFF2B2B2B),
          ),
          const SizedBox(height: 16),
          Text(
            'Uploading File',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2B2B2B)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2B2B),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
