import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/teacher/widgets/empty_student_state.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class ClassStudentListPage extends ConsumerStatefulWidget {
  final String classId;

  const ClassStudentListPage({super.key, required this.classId});

  @override
  ConsumerState<ClassStudentListPage> createState() => _ClassStudentListPageState();
}

class _ClassStudentListPageState extends ConsumerState<ClassStudentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load class detail to get enrolled students
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
      // Also load cached students immediately for offline display
      ref.read(classProvider.notifier).loadEnrolledStudentsOffline(widget.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final currentClassDetail = classState.currentClassDetail;

    ref.listen<ClassState>(classProvider, (prev, next) {
      // Offline fallback: if no cached detail and error occurred, load from local DB
      if (currentClassDetail == null &&
          next.error != null &&
          prev?.error != next.error) {
        ref.read(classProvider.notifier).loadEnrolledStudentsOffline(widget.classId);
      }
      // Show error messages
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
          'Students',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          // Determine which student list to show
          final students = currentClassDetail != null
              ? currentClassDetail.students // Online: from API
              : classState.searchResults; // Offline: from local DB

          if (classState.isLoading && students.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            );
          }

          if (students.isEmpty) {
            return const EmptyStudentState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final item = students[index];
              // Handle both Enrollment (from API) and User (from offline)
              final user = (item as dynamic).student ?? item;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {}, // No action for now
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2B2B2B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Student info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF202020),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${user.username}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}