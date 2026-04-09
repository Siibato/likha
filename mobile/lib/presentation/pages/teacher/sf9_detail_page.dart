import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/info_row.dart';
import 'package:likha/presentation/pages/teacher/widgets/sf9_grade_table.dart';
import 'package:likha/presentation/pages/teacher/widgets/sf9_print_service.dart';
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
          .read(sf9Provider.notifier)
          .loadSf9(widget.classId, widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf9Provider);
    final sf9 = state.currentSf9;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            ClassSectionHeader(
              title: 'SF9: ${widget.studentName}',
              showBackButton: true,
              trailing: sf9 != null
                  ? IconButton(
                      icon: const Icon(Icons.download_outlined),
                      color: const Color(0xFF666666),
                      tooltip: 'Download SF9',
                      onPressed: () =>
                          Sf9PrintService.printSf9(context, sf9),
                    )
                  : null,
            ),
            Expanded(
              child: state.isLoading && sf9 == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
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
                                color: Color(0xFFE57373),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : sf9 == null
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
                                          value: sf9.studentName,
                                        ),
                                        if (sf9.gradeLevel != null) ...[
                                          const SizedBox(height: 10),
                                          InfoRow(
                                            label: 'Grade Level',
                                            value: sf9.gradeLevel!,
                                          ),
                                        ],
                                        if (sf9.schoolYear != null) ...[
                                          const SizedBox(height: 10),
                                          InfoRow(
                                            label: 'School Year',
                                            value: sf9.schoolYear!,
                                          ),
                                        ],
                                        if (sf9.section != null) ...[
                                          const SizedBox(height: 10),
                                          InfoRow(
                                            label: 'Section',
                                            value: sf9.section!,
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
                                      color: Color(0xFF202020),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Sf9GradeTable(
                                    subjects: sf9.subjects,
                                    generalAverage: sf9.generalAverage,
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
