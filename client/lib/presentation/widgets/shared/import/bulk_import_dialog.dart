import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/import_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/import/csv_upload_area.dart';
import 'package:likha/presentation/widgets/shared/import/import_preview_table.dart';
import 'package:likha/presentation/widgets/shared/import/import_summary_bar.dart';

class BulkImportDialog extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const BulkImportDialog({super.key, this.onSuccess});

  @override
  ConsumerState<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends ConsumerState<BulkImportDialog> {
  _ImportStep _step = _ImportStep.upload;
  bool _isDownloading = false;

  static const _columns = [
    'username', 'first_name', 'last_name', 'lrn', 'age', 'sex',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importProvider.notifier).reset();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      ref.read(importProvider.notifier).selectFile(result.files.single.path!);
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final path = await ref.read(importProvider.notifier).downloadStudentTemplate();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template downloaded to $path'),
            backgroundColor: AppColors.semanticSuccess,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _preview() async {
    final state = ref.read(importProvider);
    if (state.selectedFilePath == null) return;
    await ref.read(importProvider.notifier).previewStudentImport(state.selectedFilePath!);
    if (mounted) setState(() => _step = _ImportStep.preview);
  }

  Future<void> _import() async {
    await ref.read(importProvider.notifier).importStudents();
    if (mounted) setState(() => _step = _ImportStep.result);
  }

  void _close() {
    Navigator.pop(context);
    final result = ref.read(importProvider).result;
    if (result != null && result.imported > 0) {
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importProvider);

    return StyledDialog(
      maxWidth: 720,
      title: 'Bulk Import Students',
      subtitle: 'Upload a CSV file to import multiple student accounts',
      content: _buildContent(state),
      actions: _buildActions(state),
    );
  }

  Widget _buildContent(ImportState state) {
    switch (_step) {
      case _ImportStep.upload:
        return _buildUploadStep(state);
      case _ImportStep.preview:
        return _buildPreviewStep(state);
      case _ImportStep.result:
        return _buildResultStep(state);
    }
  }

  Widget _buildUploadStep(ImportState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.foregroundSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Download the template, fill it with student data, then upload the CSV. '
                  'Required columns: username, first_name, last_name. All other fields are optional.',
                  style: TextStyle(fontSize: 13, color: AppColors.foregroundSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StyledButton(
              text: 'Download Template',
              isLoading: _isDownloading,
              onPressed: _downloadTemplate,
              fullWidth: false,
              variant: StyledButtonVariant.outlined,
              icon: Icons.download_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        CsvUploadArea(
          selectedFilePath: state.selectedFilePath,
          label: 'Select student CSV file',
          onPickFile: _pickFile,
          onDroppedFile: (path) => ref.read(importProvider.notifier).selectFile(path),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: AppColors.semanticError, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewStep(ImportState state) {
    if (state.preview == null) {
      return const Text('No preview data available.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImportSummaryBar(preview: state.preview!),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ImportPreviewTable(
                preview: state.preview!,
                columns: _columns,
                onRemoveRow: (index) => ref.read(importProvider.notifier).removeRow(index),
              ),
            ),
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: AppColors.semanticError, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildResultStep(ImportState state) {
    final result = state.result;
    if (result == null) {
      return const Text('No result data available.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.hasErrors ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              size: 24,
              color: result.hasErrors ? AppColors.accentAmberBorder : AppColors.semanticSuccess,
            ),
            const SizedBox(width: 8),
            Text(
              '${result.imported} students imported successfully',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foregroundDark,
              ),
            ),
          ],
        ),
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Errors:',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.semanticErrorDark, fontSize: 13),
          ),
          const SizedBox(height: 4),
          ...result.errors.map((e) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text('• $e', style: const TextStyle(fontSize: 12, color: AppColors.semanticErrorDark)),
          )),
        ],
      ],
    );
  }

  List<StyledDialogAction> _buildActions(ImportState state) {
    switch (_step) {
      case _ImportStep.upload:
        return [
          StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          StyledDialogAction(
            label: 'Preview',
            isPrimary: true,
            onPressed: state.selectedFilePath == null || state.status == ImportStatus.previewing
                ? () {}
                : _preview,
          ),
        ];
      case _ImportStep.preview:
        final canImport = state.preview != null && !state.preview!.hasErrors;
        return [
          StyledDialogAction(
            label: 'Back',
            onPressed: () => setState(() => _step = _ImportStep.upload),
          ),
          StyledDialogAction(
            label: 'Import ${state.preview?.validCount ?? 0} Students',
            isPrimary: true,
            onPressed: !canImport || state.status == ImportStatus.importing ? () {} : _import,
          ),
        ];
      case _ImportStep.result:
        return [
          StyledDialogAction(label: 'Done', isPrimary: true, onPressed: _close),
        ];
    }
  }
}

enum _ImportStep { upload, preview, result }
