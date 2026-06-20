import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/widgets/shared/primitives/class_section_header.dart';
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
    final displayName = sf9 != null && sf9.studentName == 'Unknown Student'
        ? widget.studentName
        : (sf9?.studentName ?? widget.studentName);
    final displaySf9 = sf9 != null && sf9.studentName == 'Unknown Student'
        ? Sf9Response(
            studentId: sf9.studentId,
            studentName: widget.studentName,
            gradeLevel: sf9.gradeLevel,
            schoolYear: sf9.schoolYear,
            section: sf9.section,
            gradingPeriodType: sf9.gradingPeriodType,
            subjects: sf9.subjects,
            generalAverage: sf9.generalAverage,
          )
        : sf9;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            ClassSectionHeader(
              title: 'SF9: ${widget.studentName}',
              showBackButton: true,
              trailing: null,
            ),
            Expanded(
              child: state.isLoading && displaySf9 == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentCharcoal,
                        strokeWidth: 2.5,
                      ),
                    )
                  : state.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              state.error!,
                              style: const TextStyle(
                                color: AppColors.semanticError,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : displaySf9 == null
                          ? const Center(child: Text('No data available'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Student info
                                  InfoPanel(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InfoRow(
                                          label: 'Student',
                                          value: displayName,
                                        ),
                                        if (displaySf9.gradeLevel != null) ...[
                                          const SizedBox(height: 10),
                                          InfoRow(
                                            label: 'Grade Level',
                                            value: displaySf9.gradeLevel!,
                                          ),
                                        ],
                                        if (displaySf9.schoolYear != null) ...[
                                          const SizedBox(height: 10),
                                          InfoRow(
                                            label: 'School Year',
                                            value: displaySf9.schoolYear!,
                                          ),
                                        ],
                                        if (displaySf9.section != null) ...[
                                          const SizedBox(height: 10),
                                          InfoRow(
                                            label: 'Section',
                                            value: displaySf9.section!,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Learner's Progress Report Card",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.foregroundDark,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Sf9GradeTable(
                                    subjects: displaySf9.subjects,
                                    generalAverage: displaySf9.generalAverage,
                                    gradingPeriodType: displaySf9.gradingPeriodType,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
