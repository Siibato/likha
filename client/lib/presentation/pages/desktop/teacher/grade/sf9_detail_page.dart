import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/primitives/info_row.dart';
import 'package:likha/domain/grading/entities/sf9.dart';
import 'package:likha/presentation/widgets/mobile/teacher/grade/sf9_grade_table.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

class Sf9DetailPage extends ConsumerStatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const Sf9DetailPage({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<Sf9DetailPage> createState() => _Sf9DetailPageState();
}

class _Sf9DetailPageState extends ConsumerState<Sf9DetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sf9DetailProvider.notifier)
          .loadSf9(widget.classId, widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf9DetailProvider);
    final sf9 = state.currentSf9;
    final displaySf9 = sf9 != null && sf9.studentName == 'Unknown Student'
        ? Sf9Response(
            studentId: sf9.studentId,
            studentName: widget.studentName,
            gradeLevel: sf9.gradeLevel,
            schoolYear: sf9.schoolYear,
            section: sf9.section,
            subjects: sf9.subjects,
            generalAverage: sf9.generalAverage,
          )
        : sf9;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'SF9: ${widget.studentName}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
        body: _buildBody(state, displaySf9),
      ),
    );
  }

  Widget _buildBody(Sf9DetailState state, Sf9Response? displaySf9) {
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

    if (displaySf9 == null) {
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
                InfoRow(label: 'Name', value: displaySf9.studentName),
                if (displaySf9.gradeLevel != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'Grade Level', value: displaySf9.gradeLevel!),
                ],
                if (displaySf9.schoolYear != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'School Year', value: displaySf9.schoolYear!),
                ],
                if (displaySf9.section != null) ...[
                  const SizedBox(height: 12),
                  InfoRow(label: 'Section', value: displaySf9.section!),
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
                subjects: displaySf9.subjects,
                generalAverage: displaySf9.generalAverage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
