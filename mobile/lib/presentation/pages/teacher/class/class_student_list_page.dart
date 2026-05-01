import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/domain/auth/entities/user.dart';
import 'package:likha/presentation/widgets/mobile/teacher/class/empty_student_state.dart';
import 'package:likha/presentation/pages/teacher/student_detail_page.dart';
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
      ref.read(classProvider.notifier).loadParticipantsOffline(widget.classId);
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
        ref.read(classProvider.notifier).loadParticipantsOffline(widget.classId);
      }
      // Show error messages
      if (next.error != null && prev?.error != next.error) {
        ref.read(classProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
        title: const Text(
          'Students',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
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
                color: AppColors.accentCharcoal,
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
              // Handle both Participant (from API) and User (from offline)
              final user = item is Participant ? item.student : item as User;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherStudentDetailPage(
                            student: user,
                            classId: widget.classId,
                            classTitle: currentClassDetail?.title ?? 'Class',
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentCharcoal,
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
                                      color: AppColors.foregroundDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${user.username}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.foregroundTertiary,
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