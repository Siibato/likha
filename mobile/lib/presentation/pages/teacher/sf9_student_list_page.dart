import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/base_card.dart';
import 'package:likha/presentation/pages/shared/widgets/primitives/chevron_trailing.dart';
import 'package:likha/presentation/pages/teacher/sf9_detail_page.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Student Records (SF9)',
              showBackButton: true,
            ),
            Expanded(
              child: state.isLoading && state.students.isEmpty
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
                      : state.students.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded,
                                      size: 64, color: Color(0xFFCCCCCC)),
                                  SizedBox(height: 16),
                                  Text(
                                    'No students found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2B2B2B),
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
                                            color: const Color(0xFFF0F0F0),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.person_outline_rounded,
                                              size: 22,
                                              color: Color(0xFF666666),
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
                                                  color: Color(0xFF2B2B2B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student.generalAverage != null
                                                    ? 'GA: ${student.generalAverage}'
                                                    : 'GA: --',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF999999),
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
            ),
          ],
        ),
      ),
    );
  }
}
