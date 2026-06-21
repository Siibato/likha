import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';

class CsvUploadArea extends StatefulWidget {
  final String? selectedFilePath;
  final VoidCallback onPickFile;
  final ValueChanged<String>? onDroppedFile;
  final String label;

  const CsvUploadArea({
    super.key,
    this.selectedFilePath,
    required this.onPickFile,
    this.onDroppedFile,
    this.label = 'Upload CSV File',
  });

  @override
  State<CsvUploadArea> createState() => _CsvUploadAreaState();
}

class _CsvUploadAreaState extends State<CsvUploadArea> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.selectedFilePath != null;
    final borderColor = _isDragging
        ? AppColors.accentCharcoal
        : hasFile
            ? AppColors.semanticSuccess
            : AppColors.borderLight;
    final bgColor = _isDragging
        ? AppColors.accentCharcoal.withValues(alpha: 0.05)
        : AppColors.backgroundTertiary;

    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty && widget.onDroppedFile != null) {
          final path = detail.files.first.path;
          widget.onDroppedFile!(path);
        }
      },
      onDragEntered: (detail) => setState(() => _isDragging = true),
      onDragExited: (detail) => setState(() => _isDragging = false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPickFile,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isDragging
                    ? Icons.file_download_rounded
                    : hasFile
                        ? Icons.check_circle_outline_rounded
                        : Icons.upload_file_outlined,
                size: 48,
                color: _isDragging
                    ? AppColors.accentCharcoal
                    : hasFile
                        ? AppColors.semanticSuccess
                        : AppColors.accentCharcoal,
              ),
              const SizedBox(height: 16),
              Text(
                hasFile
                    ? 'File selected: ${widget.selectedFilePath!.split(Platform.isWindows ? '\\' : '/').last}'
                    : widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foregroundDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isDragging
                    ? 'Drop the file here'
                    : hasFile
                        ? 'Click to change file'
                        : 'Click or drag a CSV file here',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foregroundDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
