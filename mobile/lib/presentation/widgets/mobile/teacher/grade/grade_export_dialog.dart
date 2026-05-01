import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/services/grade_export_service.dart';

void showGradeExportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
  required bool isDownload,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return StyledDialog(
        title: isDownload ? 'Export Grades' : 'Print Grades',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose export format:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('PDF'),
              subtitle: const Text('DepEd-style class record'),
              leading: const Icon(Icons.picture_as_pdf),
              onTap: () {
                Navigator.of(dialogContext).pop();
                if (isDownload) {
                  _exportToPdf(context, ref, classId: classId, quarter: quarter);
                } else {
                  _printGrades(context, ref, classId: classId, quarter: quarter);
                }
              },
            ),
            ListTile(
              title: const Text('Excel'),
              subtitle: const Text('Editable spreadsheet'),
              leading: const Icon(Icons.table_chart),
              onTap: () {
                Navigator.of(dialogContext).pop();
                if (isDownload) {
                  _exportToExcel(context, ref, classId: classId, quarter: quarter);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Excel export only available for download')),
                  );
                }
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

Future<void> _exportToPdf(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
}) async {
  try {
    final configState = ref.read(gradingConfigProvider);
    final itemsState = ref.read(gradeItemsProvider);
    final scoresState = ref.read(gradeScoresProvider);
    final gradesState = ref.read(quarterlyGradesProvider);
    final classState = ref.read(classProvider);

    await ref.read(gradeExportServiceProvider).exportToPdf(
      classId: classId,
      className: classState.currentClassDetail?.title ?? 'Unknown Class',
      quarter: quarter,
      students: classState.currentClassDetail?.students ?? [],
      gradeItems: itemsState.items,
      scoresByItem: scoresState.scoresByItem,
      config: configState.configs.isNotEmpty ? configState.configs.first : null,
      summary: gradesState.summary,
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

Future<void> _exportToExcel(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
}) async {
  try {
    final configState = ref.read(gradingConfigProvider);
    final itemsState = ref.read(gradeItemsProvider);
    final scoresState = ref.read(gradeScoresProvider);
    final gradesState = ref.read(quarterlyGradesProvider);
    final classState = ref.read(classProvider);

    await ref.read(gradeExportServiceProvider).exportToExcel(
      classId: classId,
      className: classState.currentClassDetail?.title ?? 'Unknown Class',
      quarter: quarter,
      students: classState.currentClassDetail?.students ?? [],
      gradeItems: itemsState.items,
      scoresByItem: scoresState.scoresByItem,
      config: configState.configs.isNotEmpty ? configState.configs.first : null,
      summary: gradesState.summary,
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

Future<void> _printGrades(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  required int quarter,
}) async {
  try {
    final configState = ref.read(gradingConfigProvider);
    final itemsState = ref.read(gradeItemsProvider);
    final scoresState = ref.read(gradeScoresProvider);
    final gradesState = ref.read(quarterlyGradesProvider);
    final classState = ref.read(classProvider);

    await ref.read(gradeExportServiceProvider).printGrades(
      classId: classId,
      className: classState.currentClassDetail?.title ?? 'Unknown Class',
      quarter: quarter,
      students: classState.currentClassDetail?.students ?? [],
      gradeItems: itemsState.items,
      scoresByItem: scoresState.scoresByItem,
      config: configState.configs.isNotEmpty ? configState.configs.first : null,
      summary: gradesState.summary,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print dialog opened!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print: $e')),
      );
    }
  }
}
