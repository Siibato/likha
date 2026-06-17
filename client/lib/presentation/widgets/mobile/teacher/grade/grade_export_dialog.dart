import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/grading_provider.dart';
import 'package:likha/presentation/providers/school_settings_provider.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';
import 'package:likha/services/grade_export_service.dart';

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
    final configState = ref.read(gradingConfigProvider);
    final itemsState = ref.read(gradeItemsProvider);
    final scoresState = ref.read(gradeScoresProvider);
    final gradesState = ref.read(quarterlyGradesProvider);
    final classState = ref.read(classProvider);
    final authState = ref.read(authProvider);
    final schoolNotifier = ref.read(schoolSettingsProvider.notifier);
    var schoolState = ref.read(schoolSettingsProvider);
    if (schoolState.settings == null) {
      await schoolNotifier.loadSchoolSettings();
      schoolState = ref.read(schoolSettingsProvider);
    }
    final detail = classState.currentClassDetail;

    await ref.read(gradeExportServiceProvider).exportToExcel(
      classId: classId,
      className: detail?.title ?? 'Unknown Class',
      quarter: quarter,
      students: detail?.students ?? [],
      gradeItems: itemsState.items,
      scoresByItem: scoresState.scoresByItem,
      config: configState.configs.isNotEmpty ? configState.configs.first : null,
      summary: gradesState.summary,
      schoolSettings: schoolState.settings,
      teacherName: authState.user?.fullName,
      gradeLevel: detail?.gradeLevel,
      section: detail?.title,
      subject: detail?.title,
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
    final configState = ref.read(gradingConfigProvider);
    final itemsState = ref.read(gradeItemsProvider);
    final scoresState = ref.read(gradeScoresProvider);
    final gradesState = ref.read(quarterlyGradesProvider);
    final classState = ref.read(classProvider);
    final authState = ref.read(authProvider);
    final schoolNotifier = ref.read(schoolSettingsProvider.notifier);
    var schoolState = ref.read(schoolSettingsProvider);
    if (schoolState.settings == null) {
      await schoolNotifier.loadSchoolSettings();
      schoolState = ref.read(schoolSettingsProvider);
    }
    final detail = classState.currentClassDetail;

    await ref.read(gradeExportServiceProvider).exportToPdf(
      classId: classId,
      className: detail?.title ?? 'Unknown Class',
      quarter: quarter,
      students: detail?.students ?? [],
      gradeItems: itemsState.items,
      scoresByItem: scoresState.scoresByItem,
      config: configState.configs.isNotEmpty ? configState.configs.first : null,
      summary: gradesState.summary,
      schoolSettings: schoolState.settings,
      teacherName: authState.user?.fullName,
      gradeLevel: detail?.gradeLevel,
      section: detail?.title,
      subject: detail?.title,
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
