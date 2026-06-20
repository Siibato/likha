import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/providers/document_export_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

void showGradeExportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int termNumber,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return _GradeExportDialogContent(
        classId: classId,
        termNumber: termNumber,
        parentContext: context,
      );
    },
  );
}

class _GradeExportDialogContent extends ConsumerWidget {
  final String classId;
  final int termNumber;
  final BuildContext parentContext;

  const _GradeExportDialogContent({
    required this.classId,
    required this.termNumber,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(documentExportProvider);

    ref.listen<DocumentExportState>(documentExportProvider, (previous, next) {
      if (previous?.isExporting == true && !next.isExporting && next.error == null) {
        Navigator.of(context).pop();
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Document exported successfully!')),
          );
        }
      }
    });

    return StyledDialog(
      title: 'Export Grades',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose export format:'),
          const SizedBox(height: 16),
          if (exportState.isExporting) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.foregroundPrimary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 12),
                    Text('Preparing document…'),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListTile(
              title: const Text('Excel'),
              subtitle: const Text('Editable spreadsheet (.xlsx)'),
              leading: const Icon(Icons.table_chart),
              onTap: () {
                ref.read(documentExportProvider.notifier).exportClassGrades(
                  classId: classId,
                  termNumber: termNumber,
                  isPdf: false,
                );
              },
            ),
            ListTile(
              title: const Text('PDF'),
              subtitle: const Text('Printable document (.pdf)'),
              leading: const Icon(Icons.picture_as_pdf),
              onTap: () {
                ref.read(documentExportProvider.notifier).exportClassGrades(
                  classId: classId,
                  termNumber: termNumber,
                  isPdf: true,
                );
              },
            ),
            if (exportState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                exportState.error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.semanticError,
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        StyledDialogAction(
          label: exportState.isExporting ? 'Exporting…' : 'Cancel',
          onPressed: exportState.isExporting
              ? () {}
              : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
