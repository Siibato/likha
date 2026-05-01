import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/mobile/mobile_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/widgets/shared/cards/base_card.dart';
import 'package:likha/presentation/widgets/shared/primitives/chevron_trailing.dart';
import 'package:likha/presentation/pages/teacher/grade/sf9_detail_page.dart';
import 'package:likha/presentation/providers/sf9_provider.dart';

class Sf9StudentListPage extends ConsumerStatefulWidget {
  final String classId;

  const Sf9StudentListPage({super.key, required this.classId});

  @override
  ConsumerState<Sf9StudentListPage> createState() =>
      _Sf9StudentListPageState();
}

class _Sf9StudentListPageState extends ConsumerState<Sf9StudentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sf9Provider.notifier).loadStudents(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sf9Provider);

    return MobilePageScaffold(
      title: 'Student Records (SF9)',
      scrollable: false,
      isLoading: state.isLoading && state.students.isEmpty,
      error: state.error,
      onRetry: () => ref.read(sf9Provider.notifier).loadStudents(widget.classId),
      header: const ClassSectionHeader(
        title: 'Student Records (SF9)',
        showBackButton: true,
      ),
      body: state.students.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded,
                                      size: 64, color: AppColors.foregroundLight),
                                  SizedBox(height: 16),
                                  Text(
                                    'No students found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentCharcoal,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: state.students.length,
                              itemBuilder: (context, index) {
                                final student = state.students[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: BaseCard(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Sf9DetailPage(
                                          classId: widget.classId,
                                          studentId: student.studentId,
                                          studentName: student.studentName,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.borderLight,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.person_outline_rounded,
                                              size: 22,
                                              color: AppColors.foregroundSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.studentName,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.accentCharcoal,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student.generalAverage != null
                                                    ? 'GA: ${student.generalAverage}'
                                                    : 'GA: --',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.foregroundTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const ChevronTrailing(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
    );
  }
}
