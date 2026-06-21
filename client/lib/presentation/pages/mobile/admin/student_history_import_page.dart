import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/data/models/import/import_preview_model.dart';
import 'package:likha/presentation/providers/import_provider.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/import/csv_upload_area.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student History Import'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foregroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TypeChip(label: 'School History', selected: _historyType == 'school_history', onTap: () {
                      setState(() => _historyType = 'school_history');
                      ref.read(importProvider.notifier).reset();
                    }),
                    const SizedBox(width: 8),
                    _TypeChip(label: 'Subjects', selected: _historyType == 'subjects', onTap: () {
                      setState(() => _historyType = 'subjects');
                      ref.read(importProvider.notifier).reset();
                    }),
                    const SizedBox(width: 8),
                    _TypeChip(label: 'Attendance', selected: _historyType == 'attendance', onTap: () {
                      setState(() => _historyType = 'attendance');
                      ref.read(importProvider.notifier).reset();
                    }),
                  ],
                ),
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
              const SizedBox(height: 12),
              if (state.preview != null && !state.preview!.hasErrors)
                StyledButton(
                  text: 'Import ${state.preview!.validCount} Records',
                  isLoading: state.status == ImportStatus.importing,
                  onPressed: state.status == ImportStatus.importing
                      ? () {}
                      : () => ref.read(importProvider.notifier).importHistory(_historyType),
                  variant: StyledButtonVariant.primary,
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
                _PreviewList(preview: state.preview!, columns: columns),
              ],
              if (state.result != null) ...[
                const SizedBox(height: 24),
                _ResultCard(result: state.result!),
              ],
            ],
          ),
        ),
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
          border: Border.all(color: selected ? AppColors.accentCharcoal : AppColors.borderLight),
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

class _PreviewList extends StatelessWidget {
  final PreviewResponseModel preview;
  final List<String> columns;

  const _PreviewList({required this.preview, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: preview.rows.map((row) {
        final hasErrors = row.hasErrors;
        final hasWarnings = row.hasWarnings;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasErrors
                ? AppColors.semanticErrorBackground.withValues(alpha: 0.5)
                : hasWarnings
                    ? AppColors.accentAmberSurface.withValues(alpha: 0.5)
                    : AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasErrors
                  ? AppColors.semanticError
                  : hasWarnings
                      ? AppColors.accentAmberBorder
                      : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Row ${row.rowIndex}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  if (hasErrors)
                    const Icon(Icons.error_outline, size: 16, color: AppColors.semanticError)
                  else if (hasWarnings)
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.accentAmberBorder)
                  else
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.semanticSuccess),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: columns.map((c) {
                  final val = row.data[c];
                  return Text(
                    '$c: ${val ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.foregroundSecondary),
                  );
                }).toList(),
              ),
              if (hasErrors) ...[
                const SizedBox(height: 4),
                ...row.errors.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $e', style: const TextStyle(fontSize: 12, color: AppColors.semanticErrorDark)),
                )),
              ],
              if (hasWarnings) ...[
                const SizedBox(height: 4),
                ...row.warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $w', style: const TextStyle(fontSize: 12, color: AppColors.accentAmberBorder)),
                )),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ImportResultModel result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Import Complete: ${result.imported} records imported',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.semanticSuccess,
            ),
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Errors (${result.errors.length}):',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.semanticErrorDark),
            ),
            ...result.errors.map((e) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('• $e', style: const TextStyle(fontSize: 13, color: AppColors.semanticErrorDark)),
            )),
          ],
        ],
      ),
    );
  }
}
