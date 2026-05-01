import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_row.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/sf9_grade_table.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/sf9_print_service.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

class Sf9DetailDesktop extends ConsumerStatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const Sf9DetailDesktop({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<Sf9DetailDesktop> createState() => _Sf9DetailDesktopState();
}

class _Sf9DetailDesktopState extends ConsumerState<Sf9DetailDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sf9Provider.notifier)
          .loadSf9(widget.classId, widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf9Provider);

    final sf9 = state.currentSf9;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'SF9: ${widget.studentName}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (sf9 != null)
            OutlinedButton.icon(
              onPressed: () => Sf9PrintService.printSf9(context, sf9),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download SF9'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foregroundPrimary,
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
        ],
        body: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(Sf9State state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.foregroundPrimary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.semanticError,
          ),
        ),
      );
    }

    final sf9 = state.currentSf9;
    if (sf9 == null) {
      return const Center(
        child: Text(
          'No SF9 data available.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.foregroundSecondary,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column — Student info
        Expanded(
          flex: 2,
          child: InfoPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Name', value: sf9.studentName),
                if (sf9.gradeLevel != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'Grade Level', value: sf9.gradeLevel!),
                ],
                if (sf9.schoolYear != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'School Year', value: sf9.schoolYear!),
                ],
                if (sf9.section != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'Section', value: sf9.section!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right column — Grade table
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Learner's Progress Report Card",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Sf9GradeTable(
                subjects: sf9.subjects,
                generalAverage: sf9.generalAverage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
