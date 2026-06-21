import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/providers/import_provider.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/import/csv_upload_area.dart';
import 'package:likha/presentation/widgets/shared/import/import_preview_table.dart';
import 'package:likha/presentation/widgets/shared/import/import_summary_bar.dart';

class BulkStudentImportPage extends ConsumerStatefulWidget {
  const BulkStudentImportPage({super.key});

  @override
  ConsumerState<BulkStudentImportPage> createState() => _BulkStudentImportPageState();
}

class _BulkStudentImportPageState extends ConsumerState<BulkStudentImportPage> {
  static const _columns = [
    'username', 'first_name', 'last_name', 'lrn', 'age', 'sex',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importProvider);

    return DesktopPageScaffold(
      title: 'Bulk Student Import',
      subtitle: 'Upload a CSV file to import multiple student accounts',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CsvUploadArea(
            selectedFilePath: state.selectedFilePath,
            label: 'Select student CSV file',
            onPickFile: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
              );
              if (result != null && result.files.single.path != null) {
                ref.read(importProvider.notifier).selectFile(result.files.single.path!);
              }
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              StyledButton(
                text: 'Preview',
                isLoading: state.status == ImportStatus.previewing,
                onPressed: state.selectedFilePath == null || state.status == ImportStatus.previewing
                    ? () {}
                    : () => ref.read(importProvider.notifier).previewStudentImport(state.selectedFilePath!),
              ),
              const SizedBox(width: 12),
              if (state.preview != null && !state.preview!.hasErrors)
                StyledButton(
                  text: 'Import ${state.preview!.validCount} Students',
                  isLoading: state.status == ImportStatus.importing,
                  onPressed: state.status == ImportStatus.importing
                      ? () {}
                      : () => ref.read(importProvider.notifier).importStudents(),
                  variant: StyledButtonVariant.primary,
                ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.semanticErrorBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.semanticError),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.semanticErrorDark, fontSize: 14),
              ),
            ),
          ],
          if (state.preview != null) ...[
            const SizedBox(height: 24),
            ImportSummaryBar(preview: state.preview!),
            const SizedBox(height: 16),
            Expanded(
              child: ImportPreviewTable(
                preview: state.preview!,
                columns: _columns,
              ),
            ),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.semanticSuccessBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.semanticSuccess),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Complete: ${state.result!.imported} students imported',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.semanticSuccess,
                    ),
                  ),
                  if (state.result!.errors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Errors (${state.result!.errors.length}):',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.semanticErrorDark),
                    ),
                    ...state.result!.errors.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• $e', style: const TextStyle(fontSize: 13, color: AppColors.semanticErrorDark)),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
