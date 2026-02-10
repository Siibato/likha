import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_search_state.dart';
import 'package:likha/presentation/pages/teacher/widgets/searchable_student_item.dart';
import 'package:likha/presentation/pages/teacher/widgets/student_search_field.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AddStudentPage extends ConsumerStatefulWidget {
  final String classId;

  const AddStudentPage({super.key, required this.classId});

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).searchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(classProvider.notifier)
          .searchStudents(query: query.isEmpty ? null : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    ref.listen<ClassState>(classProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(classProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: const Text(
          'Add Student',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: StudentSearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: classState.isLoading && classState.searchResults.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2B2B2B),
                      strokeWidth: 2.5,
                    ),
                  )
                : classState.searchResults.isEmpty
                    ? const EmptySearchState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: classState.searchResults.length,
                        itemBuilder: (context, index) {
                          final student = classState.searchResults[index];
                          final enrolledIds = classState
                                  .currentClassDetail?.students
                                  .map((e) => e.student.id)
                                  .toSet() ??
                              {};
                          final isEnrolled = enrolledIds.contains(student.id);

                          return SearchableStudentItem(
                            fullName: student.fullName,
                            username: student.username,
                            accountStatus: student.accountStatus,
                            isEnrolled: isEnrolled,
                            onAction: () {
                              if (isEnrolled) {
                                ref.read(classProvider.notifier).removeStudent(
                                      classId: widget.classId,
                                      studentId: student.id,
                                    );
                              } else {
                                ref.read(classProvider.notifier).addStudent(
                                      classId: widget.classId,
                                      studentId: student.id,
                                    );
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}