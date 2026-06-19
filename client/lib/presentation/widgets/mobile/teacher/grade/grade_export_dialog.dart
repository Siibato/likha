import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/providers/document_export_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

void showGradeExportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return StyledDialog(
        title: 'Export Grades',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Excel'),
              subtitle: const Text('Editable spreadsheet (.xlsx)'),
              leading: const Icon(Icons.table_chart),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _exportToExcel(context, ref, classId: classId, quarter: quarter);
              },
            ),
            ListTile(
              title: const Text('PDF'),
              subtitle: const Text('Printable document (.pdf)'),
              leading: const Icon(Icons.picture_as_pdf),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _exportToPdf(context, ref, classId: classId, quarter: quarter);
              },
            ),
          ],
        ),
        actions: [
          StyledDialogAction(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop()),
        ],
      );
    },
  );
}

Future<void> _exportToExcel(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
}) async {
  try {
    await ref.read(documentExportProvider.notifier).exportClassGrades(
      classId: classId,
      period: quarter,
      isPdf: false,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel exported successfully!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Excel: $e')),
      );
    }
  }
}

Future<void> _exportToPdf(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
}) async {
  try {
    await ref.read(documentExportProvider.notifier).exportClassGrades(
      classId: classId,
      period: quarter,
      isPdf: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }
}
