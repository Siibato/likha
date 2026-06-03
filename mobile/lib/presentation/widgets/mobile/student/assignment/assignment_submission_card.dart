import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/assignments/entities/assignment_submission.dart';
import 'package:likha/domain/assignments/entities/submission_file.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/cards/markdown_display.dart';
import 'package:likha/presentation/widgets/shared/primitives/card_icon_slot.dart';

/// Read-only card showing the student's submitted text content and files.
///
/// File open/save actions are surfaced via [onOpenFile] and [onSaveFile]
/// callbacks so that the page retains control over I/O operations.
class AssignmentSubmissionCard extends StatelessWidget {
  final AssignmentSubmission submission;
  final void Function(SubmissionFile file) onOpenFile;
  final void Function(SubmissionFile file) onSaveFile;

  const AssignmentSubmissionCard({
    super.key,
    required this.submission,
    required this.onOpenFile,
    required this.onSaveFile,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Submission',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          if (submission.textContent != null &&
              submission.textContent!.isNotEmpty) ...[
            const Text(
              'Text Content:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: 6),
            MarkdownDisplay(content: submission.textContent),
            if (submission.files.isNotEmpty) const SizedBox(height: 16),
          ],
          if (submission.files.isNotEmpty) ...[
            const Text(
              'Files Submitted:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...submission.files.map(
              (file) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CardIconSlot.sm(
                  icon: Icons.attach_file_rounded,
                  iconColor: AppColors.foregroundSecondary,
                ),
                title: Text(
                  file.fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCharcoal,
                  ),
                ),
                subtitle: Text(
                  _formatFileSize(file.fileSize),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.foregroundTertiary,
                  ),
                ),
                trailing: IconButton(
                  icon: kIsWeb
                      ? const Icon(Icons.open_in_browser_rounded,
                          color: AppColors.accentCharcoal)
                      : file.isCached
                          ? const Icon(Icons.folder_open_rounded)
                          : const Icon(Icons.download_rounded,
                              color: AppColors.accentCharcoal),
                  onPressed: () => kIsWeb
                      ? onOpenFile(file)
                      : file.isCached
                          ? onOpenFile(file)
                          : onSaveFile(file),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
