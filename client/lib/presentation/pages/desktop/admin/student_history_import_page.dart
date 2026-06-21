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

class StudentHistoryImportPage extends ConsumerStatefulWidget {
  const StudentHistoryImportPage({super.key});

  @override
  ConsumerState<StudentHistoryImportPage> createState() => _StudentHistoryImportPageState();
}

class _StudentHistoryImportPageState extends ConsumerState<StudentHistoryImportPage> {
  String _historyType = 'school_history';

  static const _columnMap = {
    'school_history': ['username', 'school_name', 'grade_level', 'school_year', 'section'],
    'subjects': ['username', 'school_name', 'school_year', 'subject_name', 'term_type'],
    'attendance': ['username', 'school_name', 'school_year', 'month', 'school_days'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importProvider);
    final columns = _columnMap[_historyType]!;

    return DesktopPageScaffold(
      title: 'Student History Import',
      subtitle: 'Upload CSV to import school history, subjects, or attendance',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          Row(
            children: [
              _TypeChip(
                label: 'School History',
                selected: _historyType == 'school_history',
                onTap: () {
                  setState(() => _historyType = 'school_history');
                  ref.read(importProvider.notifier).reset();
                },
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Subjects',
                selected: _historyType == 'subjects',
                onTap: () {
                  setState(() => _historyType = 'subjects');
                  ref.read(importProvider.notifier).reset();
                },
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Attendance',
                selected: _historyType == 'attendance',
                onTap: () {
                  setState(() => _historyType = 'attendance');
                  ref.read(importProvider.notifier).reset();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          CsvUploadArea(
            selectedFilePath: state.selectedFilePath,
            label: 'Select $_historyType CSV file',
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
                    : () => ref.read(importProvider.notifier).previewHistoryImport(
                          state.selectedFilePath!,
                          _historyType,
                        ),
              ),
              const SizedBox(width: 12),
              if (state.preview != null && !state.preview!.hasErrors)
                StyledButton(
                  text: 'Import ${state.preview!.validCount} Records',
                  isLoading: state.status == ImportStatus.importing,
                  onPressed: state.status == ImportStatus.importing
                      ? () {}
                      : () => ref.read(importProvider.notifier).importHistory(_historyType),
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
                columns: columns,
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
                    'Import Complete: ${state.result!.imported} records imported',
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentCharcoal : AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accentCharcoal : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onCharcoal : AppColors.foregroundDark,
          ),
        ),
      ),
    );
  }
}
